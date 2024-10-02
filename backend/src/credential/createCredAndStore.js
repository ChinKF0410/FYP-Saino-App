const sql = require('mssql');  // Import directly from mssql
const { handleConnection } = require('./Connection');
const axios = require('axios');
const dbConfig = require('../config/config');  // Database configuration
const acaPyBaseUrl = 'http://172.16.20.114:6011';  // ACA-Py base URL

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

// Main function to issue credentials and link holders to them
async function storeCredentialAndHolders(username, holders, credential) {
    const pool = await poolPromise;
    const transaction = new sql.Transaction(pool);  // Use pool in the transaction

    try {
        await transaction.begin();

        const walletData = await getWalletData(username);
        if (!walletData) {
            throw new Error(`Wallet not found for username: ${username}`);
        }

        const jwtToken = await getAuthToken(walletData.wallet_id);
        console.log("\n\n\n-----------------------------");
        const schemaId = await createSchema(credential.credentialType, jwtToken);
        const credentialDefinitionId = await createCredentialDefinition(schemaId, jwtToken);

        // Store credential
        const credentialId = await storeCredential(transaction, credential, schemaId, credentialDefinitionId);
        console.log("Credential stored successfully");

        for (const holder of holders) {
            const connectionId = await handleConnection(jwtToken, username, holder.email);
            console.log(connectionId);

            if (connectionId) {
                await storeHolder(transaction, holder, credentialId, "Pending", username);
                console.log("123123Holder stored successfully");
                console.log(holder.email);
                await sendOffer(holder, connectionId, credentialDefinitionId, schemaId, jwtToken, walletData.public_did, credential, username);
            } else {
                await storeHolder(transaction, holder, credentialId, "Holder Not Found", username);
            }
        }

        await transaction.commit();
        console.log('Holders and credentials stored successfully.');
    } catch (error) {
        await transaction.rollback();
        console.error('Error storing holders and credentials:', error);
        throw error;
    }
}

// Store credential in the Credential table
async function storeCredential(transaction, credentialData, schemaId, credentialDefinitionId) {
    const query = `
        INSERT INTO Credential (credential_type, issuance_date, schema_id, credential_definition_id)
        OUTPUT INSERTED.id
        VALUES (@credentialType, @issuanceDate, @schemaId, @credentialDefinitionId)
    `;
    const request = new sql.Request(transaction);  // Use transaction in the request

    const result = await request
        .input('credentialType', sql.NVarChar(255), credentialData.credentialType)
        .input('issuanceDate', sql.DateTime, credentialData.issuancedate)
        .input('schemaId', sql.NVarChar(255), schemaId)
        .input('credentialDefinitionId', sql.NVarChar(255), credentialDefinitionId)
        .query(query);

    return result.recordset[0].id;
}

// Store holder in the HolderCredential table
async function storeHolder(transaction, holder, credentialId, state, username) {
    const query = `
        INSERT INTO HolderCredential (holder_name, holder_email, holder_phone, holder_description, did, credential_id, statusState,username)
        VALUES (@holderName, @holderEmail, @holderPhone, @holderDescription, @did, @credentialId, @state,@username)
    `;

    const request = new sql.Request(transaction);  // Use transaction in the request

    await request
        .input('holderName', sql.NVarChar(255), holder.name)
        .input('holderEmail', sql.NVarChar(255), holder.email)
        .input('holderPhone', sql.NVarChar(50), holder.phoneNo)
        .input('holderDescription', sql.NVarChar(500), holder.description)
        .input('did', sql.NVarChar(255), holder.did)
        .input('credentialId', sql.Int, credentialId)
        .input('state', sql.NVarChar(50), state)
        .input('username', sql.NVarChar(50), username)
        .query(query);
}

// Get wallet data from Wallet table
async function getWalletData(username) {
    const pool = await poolPromise;
    try {
        const query = `SELECT wallet_id, public_did FROM Wallets WHERE username = @username`;
        const request = pool.request();  // Use pool to create request

        const result = await request
            .input('username', sql.NVarChar(50), username)
            .query(query);

        if (result.recordset.length > 0) {
            const walletData = result.recordset[0];
            console.log(`Wallet ID: ${walletData.wallet_id}, Public DID: ${walletData.public_did}`);
            return walletData;
        } else {
            console.log(`No wallet found for username: ${username}`);
            return null;
        }
    } catch (error) {
        console.error('Error retrieving wallet data:', error);
        throw new Error('Failed to retrieve wallet data');
    }
}

// Get auth token from ACA-Py
async function getAuthToken(walletID) {
    try {
        const response = await axios.post(`${acaPyBaseUrl}/multitenancy/wallet/${walletID}/token`);
        console.log('Auth Token Retrieved Successfully:', response.data);
        return response.data.token;
    } catch (error) {
        console.error('Error getting auth token:', error.response ? error.response.data : error.message);
        throw new Error('Failed to get auth token');
    }
}

// Create schema via ACA-Py
async function createSchema(schema_name, jwtToken) {
    try {
        const response = await axios.post(`${acaPyBaseUrl}/schemas`, {
            schema_name: schema_name,
            schema_version: "1.0",
            attributes: ["credentialType", "issuerName", "name", "email", "phoneNo", "description", "did", "issueDate"]
        }, {
            headers: {
                Authorization: `Bearer ${jwtToken}`,
                'Content-Type': 'application/json'
            }
        });
        console.log('Schema created successfully:', response.data.schema_id);
        return response.data.schema_id;
    } catch (error) {
        console.error('Error creating schema:', error.response ? error.response.data : error.message);
        throw error;
    }
}

// Create credential definition via ACA-Py
async function createCredentialDefinition(schemaId, jwtToken) {
    try {
        const response = await axios.post(`${acaPyBaseUrl}/credential-definitions`, {
            schema_id: schemaId,
            support_revocation: false,
            tag: "default"
        }, {
            headers: {
                Authorization: `Bearer ${jwtToken}`,
                'Content-Type': 'application/json'
            }
        });
        console.log('Credential definition created successfully:', response.data.credential_definition_id);
        return response.data.credential_definition_id;
    } catch (error) {
        console.error('Error creating credential definition:', error.response ? error.response.data : error.message);
        throw error;
    }
}

// Send credential offer via ACA-Py
async function sendOffer(holder, connectionId, credentialDefinitionId, schemaId, jwtToken, publicDid, credential, username) {
    try {
        console.log("Inside sendOffer");
        const response = await axios.post(`${acaPyBaseUrl}/issue-credential-2.0/send`, {
            "connection_id": connectionId,
            "filter": {
                "indy": {
                    "cred_def_id": credentialDefinitionId,
                    "issuer_did": publicDid,  // Your Issuer DID
                    "schema_id": schemaId,
                    "schema_version": "1.0"
                }
            },
            "credential_preview": {
                "@type": "issue-credential/2.0/credential-preview",
                "attributes": [
                    { "name": "credentialType", "value": credential.credentialType },
                    { "name": "issuerName", "value": username },
                    { "name": "name", "value": holder.name },
                    { "name": "email", "value": holder.email },
                    { "name": "phoneNo", "value": holder.phoneNo },
                    { "name": "description", "value": holder.description },
                    { "name": "did", "value": holder.did },
                    { "name": "issueDate", "value": credential.issuancedate }
                ]
            }
        }, {
            headers: {
                Authorization: `Bearer ${jwtToken}`,
                'Content-Type': `application/json`
            }
        });
        console.log('Credential offer sent successfully:', response.data);
    } catch (error) {
        console.error('Error sending credential offer:', error.response ? error.response.data : error.message);
        throw error;
    }
}


module.exports = {
    storeCredentialAndHolders
};
