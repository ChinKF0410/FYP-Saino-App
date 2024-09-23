const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const walletRoutes = require('./walletRoutes');

const appWallet = express();

// Middleware
appWallet.use(cors()); // Enable CORS
appWallet.use(bodyParser.json()); // Parse JSON request bodies

// Route handling
appWallet.use('/api/wallet', walletRoutes); 

// Root route for testing
appWallet.get('/', (req, res) => {
    res.send('Welcome to the Wallet DB API');
});

module.exports = appWallet;
