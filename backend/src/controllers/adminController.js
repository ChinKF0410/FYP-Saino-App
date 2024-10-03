const sql = require('mssql');
const dbConfig = require('../config/config');

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

// Function to verify email and update isVerified status
module.exports.VerifiedEmail = async (req, res) => {
    const { id, VerifiedStatus } = req.body; // Extract user ID and VerifiedStatus from the request body

    console.log(req.body);
    
    // Validate input
    if (!id || VerifiedStatus === undefined) {
        return res.status(400).send('ID and Verified Status are required');
    }

    try {
        const pool = await poolPromise;

        // Update isVerified status for the user
        await pool.request()
            .input('id', sql.Int, id)
            .input('VerifiedStatus', sql.Int, VerifiedStatus)
            .query(`
                UPDATE [User]
                SET isVerified = @VerifiedStatus
                WHERE UserID = @id
            `);

        console.log(`Verified status for UserID ${id} updated to ${VerifiedStatus}`);
        res.status(200).json({ status: `Verified Status is updated to ${VerifiedStatus}` });

    } catch (err) {
        console.error('Error updating verified status:', err.message);
        res.status(500).send('Internal Server Error');
    }
};

// Function to fetch unverified users
module.exports.getUnverifiedUsers = async (req, res) => {
    console.log("Admin Fetching Unverified Users via POST");

    try {
        const pool = await poolPromise;

        // Fetch users where isVerified is 0 (unverified)
        const result = await pool.request()
            .query(`
                SELECT UserID, Username, Email, CompanyName, isVerified 
                FROM [User]
                WHERE isVerified = 0
            `);

        const users = result.recordset;
        console.log(`${users.length} unverified users fetched.`);
        res.status(200).json(users);

    } catch (err) {
        console.error('Error fetching unverified users:', err.message);
        res.status(500).send('Internal Server Error');
    }
};