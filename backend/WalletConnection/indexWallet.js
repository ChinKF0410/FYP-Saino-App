const appWallet = require('./appWallet');
const port = process.env.PORT_Wallet || 3001; 

// Start server
appWallet.listen(port, () => {
    console.log(`Wallet API server is running on http://localhost:${port}`);
});
