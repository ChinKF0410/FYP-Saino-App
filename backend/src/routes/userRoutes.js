const express = require('express');
const { login, register, logout } = require('../controllers/userController');
const { addHolderAndCredential } = require('../controllers/holdersController');
const { generateQRCode, searchQRCode } = require('../controllers/qrController');
const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.post('/logout', logout);
router.post('/addHolderAndCredential', addHolderAndCredential);
router.post('/generate-qrcode', generateQRCode);

// New route for searching QR code by hash value
router.post('/search-qrcode', searchQRCode);

module.exports = router;
