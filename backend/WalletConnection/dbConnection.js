const sql = require('mssql');
const dbConfigWallet = require('./dbConfigWallet');

const connectWalletDB = async () => {
    try {
        const pool = await sql.connect(dbConfigWallet);
        console.log('Connected to MSSQL Wallet DB successfully.');
        return pool;
    } catch (err) {
        console.error('Failed to connect to MSSQL Wallet DB:', err);
        process.exit(1);
    }
};

module.exports = { connectWalletDB };
