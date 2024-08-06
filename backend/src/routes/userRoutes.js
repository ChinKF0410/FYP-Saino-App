const express = require('express');
const { login, register, /*verifyEmail,*/ logout } = require('../controllers/userController');
//const { sendVerificationEmail } = require('../services/emailService')
const router = express.Router();

router.post('/login', login);
router.post('/register', register);
/*router.get('/verify-email', verifyEmail);
router.post('/send-verification-email', (req, res, next) => {
    console.log(req.body);  // Log the request body to see what data is received
    next();  // Pass control to the next handler
}, sendVerificationEmail);
*/
router.post('/logout', logout);

module.exports = router;
