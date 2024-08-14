const express = require('express');
const { login, register, logout } = require('../controllers/userController');
const { addHolderAndCredential } = require('../controllers/holdersController');
const { generateQRCode, searchQRCode, fetchQRCodesByUserId } = require('../controllers/qrController'); // Import the new function
const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.post('/logout', logout);
router.post('/addHolderAndCredential', addHolderAndCredential);
router.post('/generate-qrcode', generateQRCode);

// Route for searching QR code by hash value
router.post('/search-qrcode', searchQRCode);

// New route for fetching QR codes by user ID
router.post('/fetch-qrcodes', fetchQRCodesByUserId); // Add this line

module.exports = router;
