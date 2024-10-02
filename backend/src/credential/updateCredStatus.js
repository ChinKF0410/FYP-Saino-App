const sql = require('mssql');  // Import directly from mssql
const dbConfig = require('../config/config');  // Database configuration

let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

async function UpdateStatus(req, res) {
    console.log("Updating credential status");
    try {
        const { message, credential } = req.body; // Extract message and credential from the request body
        console.log("Message:", message);
        console.log('Credential Data:', JSON.stringify(credential, null, 2));

        if (!message || !credential) {
            return res.status(400).send('Message or Credential is Missing');
        }

        // Extract credential data
        const {
            credentialType, // credential_type
            issueDate, // issuance_date
            name, // holder_name
            email, // holder_email
            phoneNo, // holder_phone
            description, // holder_description
            did
        } = credential;

        // Determine the status based on the message content
        let newStatus;
        if (message.includes("Credential Rejected")) {
            newStatus = "Rejected";
        } else if (message.includes("Credential Accepted")) {
            newStatus = "Accepted";
        } else {
            newStatus = "Pending"; // Default or other status
        }
        console.log("New Status:", newStatus);
        
        // Fetch the credential_id from the Credential table based on credentialType and issueDate
        const pool = await poolPromise;
        const credentialResult = await pool.request()
            .input('credentialType', sql.NVarChar(255), credentialType)
            .input('issueDate', sql.DateTime, issueDate)
            .query(`
                SELECT id
                FROM Credential
                WHERE credential_type = @credentialType
                  AND issuance_date = @issueDate
            `);

        if (credentialResult.recordset.length === 0) {
            return res.status(404).send('Credential Not Found');
        }

        const credential_id = credentialResult.recordset[0].id;
        console.log("Credential ID:", credential_id);

        // Update the HolderCredential table based on the credential_id and holder data
        const updateResult = await pool.request()
            .input('credentialId', sql.Int, credential_id)
            .input('name', sql.NVarChar(255), name)
            .input('email', sql.NVarChar(255), email)
            .input('phone', sql.NVarChar(50), phoneNo)
            .input('description', sql.NVarChar(500), description)
            .input('did', sql.NVarChar(255), did)
            .input('newStatus', sql.NVarChar(50), newStatus) // Set status based on the message
            .query(`
                UPDATE HolderCredential
                SET statusState = @newStatus
                WHERE credential_id = @credentialId
                  AND holder_name = @name
                  AND holder_email = @email
                  AND holder_phone = @phone
                  AND holder_description = @description
                  AND did = @did
            `);

        console.log("Status updated to", newStatus);
        res.json({ message: `Status updated to ${newStatus}` });
    } catch (err) {
        console.error('SQL error', err);
        res.status(500).send('Internal Server Error');
    }
}

module.exports = { UpdateStatus };
