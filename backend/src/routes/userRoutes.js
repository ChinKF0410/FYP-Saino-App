const express = require('express');
const { login, register, logout, verifyPassword, changePassword, getProfile, saveProfile } = require('../controllers/userController');
const { addHolderAndCredential } = require('../controllers/holdersController');
const { search, showDetails } = require('../controllers/searchController');

const router = express.Router();

router.post('/login', login);
router.post('/register', register);
router.post('/logout', logout);
router.post('/addHolderAndCredential', addHolderAndCredential);

router.post('/search-talent', search);
router.post('/showDetails', showDetails);
router.post('/verifyPassword', verifyPassword);
router.post('/changePassword', changePassword);
 router.post('/getProfile', getProfile);
 router.post('/saveProfile', saveProfile);



module.exports = router;
