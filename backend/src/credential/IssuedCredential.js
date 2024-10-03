const sql = require('mssql');  // Import directly from mssql
const dbConfig = require('../config/config');  // Database configuration


// Initialize SQL connection pool
let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });


    async function ViewCredential(req, res) {
        console.log("get the issue data");
        try {
            const { Email } = req.body; // Extract Email from the request body
    
            if (!Email) {
                return res.status(400).send('Email is required');
            }
    
            const pool = await poolPromise;
    
            // Use parameterized queries to prevent SQL injection
            const result = await pool.request()
                .input('Email', Email) // Pass the Email as a parameter
                .query(`
                    SELECT 
                        holder_id AS id,
                        holder_name AS name,
                        holder_email AS email,
                        holder_phone AS phone,
                        holder_description AS description,
                        did,
                        statusState AS status
                    FROM HolderCredential
                    WHERE Email = @Email
                    ORDER BY id DESC;
                `);
    
            console.log("done get issue data");
            res.json(result.recordset);
        } catch (err) {
            console.error('SQL error', err);
            res.status(500).send('Internal Server Error');
        }
    }
    module.exports = {ViewCredential };