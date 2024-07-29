const nodemailer = require('nodemailer');
const { google } = require('google-auth-library');
const jwt = require('jsonwebtoken'); // Ensure jwt is imported if used

// OAuth2 Credentials
const CLIENT_ID = '9955399644-69drjbaiptk1jq6gic2q58gegdk0adf7.apps.googleusercontent.com';
const CLIENT_SECRET = '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';
const REDIRECT_URI = 'https://developers.google.com/oauthplayground';
const REFRESH_TOKEN = '1//04u38REprQlPOCgYIARAAGAQSNwF-L9Ir8hoYuRsXviFMU8Shn7Oe_5UhSvFWWqiZsM8L1AFqNNk3Bm0vq3lB5JnAQSFYOfMhdjUn';

const oAuth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

// Function to send verification email
module.exports.sendVerificationEmail = async (email, userId) => {
    const token = jwt.sign({ userId }, 'your_jwt_secret', { expiresIn: '1h' });
    const verificationUrl = `http://127.0.0.1:3000/api/verify-email?token=${token}`;

    try {
        const accessToken = await oAuth2Client.getAccessToken();
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                type: 'OAuth2',
                user: 'chinxuanhong5328@gmail.com',
                clientId: CLIENT_ID,
                clientSecret: CLIENT_SECRET,
                refreshToken: REFRESH_TOKEN,
                accessToken: accessToken.token,
            }
        });

        const mailOptions = {
            from: 'CHIN <chinxuanhong5328@gmail.com>',  // Customize the sender address
            to: email,
            subject: 'Verify Your Email Address',
            html: `<p>Please verify your email by clicking on the link below:</p><a href="${verificationUrl}">Verify Email</a>`
        };

        const result = await transporter.sendMail(mailOptions);
        console.log('Verification email sent to:', email, 'Result:', result);
    } catch (error) {
        console.error('Failed to send verification email:', error);
    }
};
