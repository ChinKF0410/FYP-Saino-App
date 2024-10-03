const sql = require('mssql');  // Import directly from mssql
const axios = require('axios'); // For making external API requests
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

async function DeleteStatus(req, res) {
    console.log("Update Delete Status");
    try {
        const { id, name, email } = req.body; // Extract data from the request body

        if (!id) {
            return res.status(400).send('ID is required');
        }

        const pool = await poolPromise;
        const state = "Deleted";

        // Update status to "Deleted"
        await pool.request()
            .input('id', sql.Int, id)
            .input('newStatus', sql.NVarChar(50), state)
            .query(`
                UPDATE HolderCredential
                SET statusState = @newStatus
                WHERE holder_id = @id
            `);

        console.log("Status updated to 'Deleted'");

        // Step 1: Retrieve the credential_id based on holder_id
        const result = await pool.request()
            .input('id', sql.Int, id)
            .query(`
                SELECT credential_id
                FROM HolderCredential
                WHERE holder_id = @id
            `);

        const credentialId = result.recordset[0]?.credential_id;

        if (!credentialId) {
            return res.status(404).send('Credential ID not found');
        }

        // Step 2: Fetch credential_type and issuance_date based on credential_id
        const credentialResult = await pool.request()
            .input('credential_id', sql.Int, credentialId)
            .query(`
                SELECT credential_type, issuance_date
                FROM Credential
                WHERE id = @credential_id
            `);

        const credentialData = credentialResult.recordset[0];

        if (!credentialData) {
            return res.status(404).send('Credential details not found');
        }

        console.log("Fetched credential details:", credentialData);

        // Step 3: Call updateActive API and pass the necessary values
        const message = await updateActive(
            credentialData.issuance_date,
            credentialData.credential_type,
            name,
            email
        );
        console.log(message);

        // Return success response with credential details
        res.json({
            message: "Status updated to 'Deleted' and credential details fetched",
            credential_type: credentialData.credential_type,
            issuance_date: credentialData.issuance_date
        });

    } catch (err) {
        console.error('SQL error', err);
        res.status(500).send('Internal Server Error');
    }
}

async function updateActive(issuance_date, credential_type, name, email) {
    try {
        console.log("\n\nUpdating Wallet");
        
        // Send the required data to the external API
        await axios.post(
            `http://192.168.1.9:4000/api/UpdateActive`,
            {
                issuance_date,
                credential_type,
                name,
                email
            }
        );

        console.log("\n\nUpdated Wallet Status");

        return "Wallet status updated to Active";
    } catch (error) {
        console.error('Error updating wallet status', error.response ? error.response.data : error.message);
        throw new Error('Failed to update wallet status');
    }
}

module.exports = { DeleteStatus };
