// Import necessary modules
const axios = require('axios');
const sql = require('mssql');
const dbConfig = require('../config/config');
sql.globalConnectionPool = false;
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

// Function to verify UserID and update isVerified status
module.exports.VerifiedUserID = async (req, res) => {
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
        if (VerifiedStatus === 1) {
            // Only call fetchUserAcc if VerifiedStatus is set to 1 (for example, "approved")
            await module.exports.fetchUserAcc({
                body: { UserID: id }
            }, {
                status: (code) => ({
                    json: (message) => console.log(`fetchUserAcc status: ${code}, message: ${JSON.stringify(message)}`)
                })
            });
        }
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
                SELECT UserID, Username,Email, CompanyName, isVerified 
                FROM [User]
                WHERE isVerified = 0
            `);

        const users = result.recordset;
        console.log(users);
        console.log(`${users.length} unverified users fetched.`);
        res.status(200).json(users);

    } catch (err) {
        console.error('Error fetching unverified users:', err.message);
        res.status(500).send('Internal Server Error');
    }
};

module.exports.fetchUserAcc = async (req, res) => {
    const { UserID } = req.body;

    // Step 1: Validate Input
    if (UserID === undefined || UserID === null) {
        return res.status(400).json({ message: 'UserID is required' });
    }

    try {
        const pool = await poolPromise;

        // Step 2: Fetch User Credentials
        const result = await pool.request()
            .input('UserID', sql.Int, UserID)
            .query(`
                SELECT Email, Password
                FROM [User]
                WHERE UserID = @UserID
            `);

        if (result.recordset.length === 0) {
            // User not found
            return res.status(404).json({ message: 'User not found' });
        }

        const user = result.recordset[0];
        const email = user.Email;
        const password = user.Password;

        // Validate fetched data
        if (!email || !password) {
            return res.status(400).json({ message: 'Email or password is missing for this user.' });
        }

        const vonApiUrl = 'http://10.123.10.108:6011/api/createWalletandDID'; // Replace with actual URL
        const vonResponse = await axios.post(vonApiUrl, {
            email: email,
            password: password
        }, {
            headers: {
                'Content-Type': 'application/json'
                // Add other headers if required by VON Network API
            },
            timeout: 10000 // Optional: Set a timeout for the request
        });

        // Step 4: Return VON Network API Response
        return res.status(vonResponse.status).json(vonResponse.data);

    } catch (error) {
        console.error('Error in fetchUserAcc:', error);

        // Handle Axios errors
        if (error.response) {
            // VON Network API responded with a status other than 2xx
            return res.status(error.response.status).json({
                message: error.response.data.message || 'Error from VON Network API',
                details: error.response.data
            });
        } else if (error.request) {
            // No response received from VON Network API
            return res.status(502).json({ message: 'No response from VON Network API' });
        } else {
            // Other errors (e.g., code errors)
            return res.status(500).json({ message: 'Internal Server Error' });
        }
    }
};