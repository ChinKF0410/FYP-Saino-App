const express = require('express');
const { receiveConnection } = require('../src/credential/function/receiveConnection');
const { generateQRCode, searchQRCode, fetchQRCodesByUserId } = require('./qrController');
const { receiveOffer } = require('../src/credential/function/receiveOffer');
// Import the controller functions
const { createWalletandDID } = require('../src/credential/function/acapyRegister');


const router = express.Router();

router.post('/generateQRCode', generateQRCode);
router.post('/search-qrcode', searchQRCode);
router.post('/fetch-qrcodes', fetchQRCodesByUserId);
router.post('/receiveOffer', receiveOffer)
router.post('/receiveConnection', receiveConnection);
router.post('/createWalletandDID', createWalletandDID);


module.exports = router;
