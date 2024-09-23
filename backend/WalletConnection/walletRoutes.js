const express = require('express');
const { generateQRCode, searchQRCode, fetchQRCodesByUserId } = require('./qrController');
 // Import the controller functions

const router = express.Router();

router.post('/generate-qrcode', generateQRCode);
router.post('/search-qrcode', searchQRCode);
router.post('/fetch-qrcodes', fetchQRCodesByUserId);

module.exports = router;
