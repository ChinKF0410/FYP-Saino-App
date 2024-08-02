// src/services/emailService.js
require('dotenv').config(); // Load environment variables

// Import required modules
const nodemailer = require('nodemailer');
const { google } = require('googleapis');
const jwt = require('jsonwebtoken');

// Load environment variables
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;
const REDIRECT_URI = process.env.REDIRECT_URI;
const REFRESH_TOKEN = process.env.REFRESH_TOKEN;
const JWT_SECRET = process.env.JWT_SECRET;
console.log('JWT_SECRET:', JWT_SECRET);  // Debug: Verify JWT_SECRET is loaded

// Initialize the OAuth2 client with credentials
const oAuth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);
oAuth2Client.setCredentials({ refresh_token: REFRESH_TOKEN });

// Function to send verification email
module.exports.sendVerificationEmail = async (email, userId) => {
    // Generate a JWT token for email verification
    const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '1h' });
    const verificationUrl = `http://127.0.0.1:3000/api/verify-email?token=${token}`;

    try {
        // Obtain a new access token using the refresh token
        const { token: accessToken } = await oAuth2Client.getAccessToken();

        // Create a transporter using Nodemailer with OAuth2 authentication
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                type: 'OAuth2',
                user: 'chinxuanhong5328@gmail.com',
                clientId: CLIENT_ID,
                clientSecret: CLIENT_SECRET,
                refreshToken: REFRESH_TOKEN,
                accessToken: accessToken, // Use the correct access token
            }
        });

        // Define email options
        const mailOptions = {
            from: 'CHIN <chinxuanhong5328@gmail.com>',
            to: email,
            subject: 'Verify Your Email Address',
            html: `<p>Please verify your email by clicking on the link below:</p><a href="${verificationUrl}">Verify Email</a>`
        };

        // Send email using the transporter
        const result = await transporter.sendMail(mailOptions);
        console.log('Verification email sent to:', email, 'Result:', result);
    } catch (error) {
        console.error('Failed to send verification email:', error);
    }
};
