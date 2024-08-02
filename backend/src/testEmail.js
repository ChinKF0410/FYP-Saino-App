// src/testEmail.js

const { sendVerificationEmail } = require('./services/emailService');

// Test email function
const testEmail = async () => {
    console.log('CLIENT_ID:', process.env.CLIENT_ID);  // Debug
    console.log('CLIENT_SECRET:', process.env.CLIENT_SECRET);  // Debug
    console.log('REDIRECT_URI:', process.env.REDIRECT_URI);  // Debug
    console.log('REFRESH_TOKEN:', process.env.REFRESH_TOKEN);  // Debug
    console.log('JWT_SECRET:', process.env.JWT_SECRET);  // Debug

    const testEmailAddress = 'chinxuanhong5328@gmail.com';  // Replace with a valid email address for testing
    const userId = '12345';  // Use a test user ID

    try {
        await sendVerificationEmail(testEmailAddress, userId);
        console.log('Email sent successfully');
    } catch (error) {
        console.error('Error sending email:', error);
    }
};

// Call the test function
testEmail();
