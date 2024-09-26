const axios = require('axios');
const sql = require('mssql');
const dbConfig = require('../../config/config'); // Import database configuration

// ACA-Py API endpoint configuration
const acaPyBaseUrl = 'http://localhost:6011';  // Issuer API URL || holder is 7011

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

  // Function to wait for a specified number of milliseconds
    async function wait(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

// Run this function to create connection
async function Connection(req, res) {
    const { username, holderEmail } = req.body;
    try {
        // Step 1: Get wallet ID and DID for the user
        const walletData = await getWalletData(username);
        if (!walletData) {
            return res.status(404).json({ message: 'Wallet not found for the user' });
        }

        const walletID = walletData.wallet_id;
        const publicDID = walletData.public_did;

        // Step 2: Get auth token
        const authToken = await getAuthToken(walletID);

        // Step 3: Check if connection exists, if not, create connection, if exists, get the connection ID
        const conn_id = await handleConnection(authToken, username, holderEmail);

        res.status(200).json({
            message: 'Connection created successfully',
            conn_id
        });
    } catch (error) {
        console.error('Error:', error.message);
        res.status(500).json({ message: 'Failed to create connection' });
    }
}

// Create a new connection with ACA-Py
async function createConnection(jwtToken) {
    try {
        const response = await axios.post(
            `${acaPyBaseUrl}/connections/create-invitation`,
            {
                "auto_accept": true,
                "multi_use": false,
                "alias": "Connection to Holder"
            },
            {
                headers: {
                    Authorization: `Bearer ${jwtToken}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        console.log('Connection Created', response.data.invitation);
        return response.data;
    } catch (error) {
        console.error('Error creating connection', error.response ? error.response.data : error.message);
        throw new Error('Failed to create connection');
    }
}

// Send connection invitation to holder Node.js project
async function sendConnection(invitation, holder, issuer) {
    try {
        console.log("\n\nsendConnection started");
        console.log(invitation);
        console.log(holder);
        console.log(issuer);
        const response = await axios.post(
            `http://localhost:3000/api/receiveConnection`,
            { invitation, holder, issuer }
        );
        console.log("\n\nsendConnection Ended");

        console.log('Connection Sent To Holder', response.data);
        return response.data;
    } catch (error) {
        console.error('Error sending connection', error.response ? error.response.data : error.message);
        throw new Error('Failed to send connection');
    }
}
// Check if the connection already exists in the database
async function checkConnectionExists(username, holderEmail) {
    try {
        const pool = await poolPromise; // Use the pool connection
        const query = `
            SELECT connection_id 
            FROM connection 
            WHERE username = @username AND holderEmail = @holderEmail
        `;

        const request = pool.request(); // Create a request using the pool connection
        const result = await request
            .input('username', sql.NVarChar(50), username)
            .input('holderEmail', sql.NVarChar(50), holderEmail)
            .query(query);

        if (result.recordset.length > 0) {
            return result.recordset[0].connection_id;
        }
        return null;  // No connection exists
    } catch (error) {
        console.error('Error checking connection existence:', error);
        throw new Error('Failed to check connection existence');
    }
}

// Store a new connection in the database
async function storeConnection(username, connectionId, holderEmail) {
    try {
        const pool = await poolPromise; // Use the pool connection
        const query = `
            INSERT INTO connection (username, connection_id, holderEmail, status) 
            VALUES (@username, @connectionId, @holderEmail, @status)
        `;

        const request = pool.request();  // Create a request using the pool connection
        await request
            .input('username', sql.NVarChar(50), username)
            .input('connectionId', sql.NVarChar(255), connectionId)
            .input('status', sql.NVarChar(50), "active")
            .input('holderEmail', sql.NVarChar(255), holderEmail)
            .query(query);

        console.log('New connection stored successfully.');
    } catch (error) {
        console.error('Error storing connection:', error);
        throw new Error('Failed to store connection');
    }
}

// Check connection existence or create a new connection
async function handleConnection(authToken, username, holderEmail) {
    try {
        // Check if the connection already exists
        const existingConnectionId = await checkConnectionExists(username, holderEmail);

        if (existingConnectionId) {
            // If the connection exists, return the existing connection ID
            console.log('Connection already exists:', existingConnectionId);
            return existingConnectionId;
        } else {
            // If the connection does not exist, create a new connection
            const Connectiondata = await createConnection(authToken);
            const newConnectionId = Connectiondata.connection_id;
            const conn_inv = Connectiondata.invitation;

            // Send connection to holder Node.js
            const connectionResponse = await sendConnection(conn_inv, holderEmail, username);

            // Wait for 5 seconds
            await wait(5000);

            // Check the message in the response to determine the status
            if (connectionResponse.message === 'Holder received the connection') {
                // Connection was successful, store it in the database
                await storeConnection(username, newConnectionId, holderEmail);
                return newConnectionId;
            } else {
                // If the message indicates failure, return null
                console.error('Connection failed:', connectionResponse.message);
                return null;
            }
        }
    } catch (error) {
        console.error('Error handling connection:', error);
        throw new Error('Failed to handle connection');
    }
}

// Get wallet data from Wallet table
async function getWalletData(username) {
    try {
        const pool = await poolPromise;  // Use the pool connection
        const query = `SELECT wallet_id, public_did FROM Wallets WHERE username = @username`;

        const request = pool.request();  // Create a request using the pool connection
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

module.exports = { Connection, handleConnection };
