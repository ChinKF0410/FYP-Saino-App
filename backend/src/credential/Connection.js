/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const axios = require('axios');
const sql = require('mssql');
const dbConfig = require('../config/config'); // Import database configuration

// ACA-Py API endpoint configuration
const acaPyBaseUrl = 'http://172.16.20.26:6011';  // Issuer API URL || holder is 7011

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
    const { Email, holderEmail } = req.body;
    try {
        // Step 1: Get wallet ID and DID for the user
        const walletData = await getWalletData(Email);
        if (!walletData) {
            return res.status(404).json({ message: 'Wallet not found for the user' });
        }

        const walletID = walletData.wallet_id;
        const publicDID = walletData.public_did;

        // Step 2: Get auth token
        const authToken = await getAuthToken(walletID);

        // Step 3: Check if connection exists, if not, create connection, if exists, get the connection ID
        const conn_id = await handleConnection(authToken, Email, holderEmail);

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
            `http://172.16.20.26:4000/api/receiveConnection`,
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
async function checkConnectionExists(Email, holderEmail) {
    try {
        const pool = await poolPromise; // Use the pool connection
        const query = `
            SELECT connection_id 
            FROM connection 
            WHERE Email = @Email AND holderEmail = @holderEmail
        `;

        const request = pool.request(); // Create a request using the pool connection
        const result = await request
            .input('Email', sql.NVarChar(50), Email)
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
async function storeConnection(Email, connectionId, holderEmail) {
    try {
        const pool = await poolPromise; // Use the pool connection
        const query = `
            INSERT INTO connection (Email, connection_id, holderEmail, status) 
            VALUES (@Email, @connectionId, @holderEmail, @status)
        `;

        const request = pool.request();  // Create a request using the pool connection
        await request
            .input('Email', sql.NVarChar(50), Email)
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
async function handleConnection(authToken, Email, holderEmail) {
    try {
        // Check if the connection already exists
        const existingConnectionId = await checkConnectionExists(Email, holderEmail);

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
            const connectionResponse = await sendConnection(conn_inv, holderEmail, Email);

            // Wait for 5 seconds
            await wait(5000);

            // Check the message in the response to determine the status
            if (connectionResponse.message === 'Holder received the connection') {
                // Connection was successful, store it in the database
                await storeConnection(Email, newConnectionId, holderEmail);
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
async function getWalletData(Email) {
    try {
        const pool = await poolPromise;  // Use the pool connection
        const query = `SELECT wallet_id, public_did FROM Wallets WHERE Email = @Email`;

        const request = pool.request();  // Create a request using the pool connection
        const result = await request
            .input('Email', sql.NVarChar(50), Email)
            .query(query);

        if (result.recordset.length > 0) {
            const walletData = result.recordset[0];
            console.log(`Wallet ID: ${walletData.wallet_id}, Public DID: ${walletData.public_did}`);
            return walletData;
        } else {
            console.log(`No wallet found for Email: ${Email}`);
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
