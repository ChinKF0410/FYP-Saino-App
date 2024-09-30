const sql = require('mssql');
const dbConfig = require('../config/config');
sql.globalConnectionPool = false;

let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL SAINO DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

// module.exports.backdoorReset = async (req, res) => {
//     let transaction;
//     try {
//         const pool = await poolPromise;

//         // Start a transaction
//         transaction = pool.transaction();
//         await transaction.begin();

//         const request = transaction.request();

//         // Execute delete queries for the specified tables
//         await request.query('DELETE FROM Education');
//         await request.query('DELETE FROM Certification');
//         await request.query('DELETE FROM Work');
//         await request.query('DELETE FROM SoftSkill');
//         await request.query('DELETE FROM Profile');
//         await request.query('DELETE FROM Account');

//         // Commit the transaction if all delete operations are successful
//         await transaction.commit();

//         console.log('All specified tables in SAINO have been cleared.');
//         return res.status(200).send('All records have been deleted successfully.');
//     } catch (err) {
//         console.error('Error resetting tables:', err);

//         // If an error occurs, rollback the transaction
//         if (transaction) {
//             await transaction.rollback();
//         }

//         return res.status(500).send('Error resetting tables.');
//     }
// };



module.exports.backdoorReset = async (req, res) => {
    let transaction;
    try {
        const pool = await poolPromise;
        
        // Start a transaction
        transaction = pool.transaction();
        await transaction.begin();

        const request = transaction.request();

        // Disable all foreign key constraints
        await request.query('EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"');

        // Delete data from all tables
        await request.query(`
            DECLARE @sql NVARCHAR(MAX) = N'';
            SELECT @sql += 'DELETE FROM [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']; '
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_TYPE = 'BASE TABLE';
            EXEC sp_executesql @sql;
        `);

        // Re-enable all foreign key constraints
        await request.query('EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"');

        // Commit the transaction
        await transaction.commit();

        console.log('All tables in the database have been cleared.');
        return res.status(200).send('All records from all tables have been deleted successfully.');
    } catch (err) {
        console.error('Error resetting all tables:', err);

        // If an error occurs, rollback the transaction
        if (transaction) {
            await transaction.rollback();
        }

        return res.status(500).send('Error resetting tables.');
    }
};
