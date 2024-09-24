const express = require('express');
const { login, register, logout, verifyPassword, changePassword, getProfile, saveProfile } = require('../controllers/userController');
const { search, showDetails } = require('../controllers/searchController');
const { createWalletandDID } = require('../controllers/acapyRegister');
const { storeCredentialAndHolders } = require('../credential/function/createCredAndStore');
const { Connection, handleConnection } = require('../credential/function/Connection');
const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.post('/logout', logout);

router.post('/search-talent', search);
router.post('/showDetails', showDetails);
router.post('/verifyPassword', verifyPassword);
router.post('/changePassword', changePassword);
router.post('/getProfile', getProfile);
router.post('/saveProfile', saveProfile);

router.post('/createWalletandDID', createWalletandDID);
router.post('/connection', Connection);
// Route to handle connection creation
router.post('/createCredential', async (req, res) => {
    try {
        const { user, holders, credential } = req.body;
        console.log(req.body);
        // Call the function to store holders and credential
        await storeCredentialAndHolders(user, holders, credential);

        res.status(201).json({
            message: 'Credential issued and holders linked successfully'
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({
            message: 'Failed to issue credential and store holders',
            error: error.message
        });
    }
});
router.post('/connection', Connection);

module.exports = router;
