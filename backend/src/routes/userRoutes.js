const express = require('express');
const { login, register, logout } = require('../controllers/userController');
const { addHolderAndCredential } = require('../controllers/holdersController');
const { generateQRCode, searchQRCode, fetchQRCodesByUserId } = require('../controllers/qrController');
const { search, showDetails } = require('../controllers/searchController');

const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.post('/logout', logout);
router.post('/addHolderAndCredential', addHolderAndCredential);
router.post('/generate-qrcode', generateQRCode);
router.post('/search-qrcode', searchQRCode);
router.post('/fetch-qrcodes', fetchQRCodesByUserId);
router.post('/search-talent', search);
router.post('/showDetails', showDetails); // Changed to POST

module.exports = router;
