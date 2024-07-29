const sql = require('mssql');
const bcrypt = require('bcryptjs');
const { sendVerificationEmail } = require('../services/emailService');
const jwt = require('jsonwebtoken');
const dbConfig = require('../config/config');

// Initialize SQL connection pool
let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });

module.exports.login = async (req, res) => {
    const { email, password } = req.body;
    console.log(`Login attempt with email: ${email}`);
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT UserID, Username, Password, UserEmailVerified FROM [User] WHERE Email = @email');
        console.log('Query result:', result);

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            console.log('User found:', user);
            const isPasswordValid = await bcrypt.compare(password, user.Password);
            console.log('Password valid:', isPasswordValid);
            if (isPasswordValid) {
                res.status(200).json({
                    id: user.UserID,
                    username: user.Username,
                    emailVerified: user.UserEmailVerified === 1 // Assuming SQL Server returns 1 for true
                });
            } else {
                res.status(401).send('Invalid email or password');
            }
        } else {
            res.status(401).send('Invalid email or password');
        }
    } catch (err) {
        console.error('Login Error: ', err);
        res.status(500).send('Server error');
    }
};

module.exports.register = async (req, res) => {
    const { username, email, password } = req.body;
    try {
        const pool = await poolPromise;
        const userExists = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT UserID FROM [User] WHERE Email = @email');

        if (userExists.recordset.length > 0) {
            res.status(400).send('Email already in use');
        } else {
            const hashedPassword = await bcrypt.hash(password, 10);
            const result = await pool.request()
                .input('username', sql.VarChar, username)
                .input('email', sql.VarChar, email)
                .input('password', sql.VarChar, hashedPassword)
                .input('emailVerified', sql.Bit, 0)
                .query('INSERT INTO [User] (Username, Email, Password, UserEmailVerified) OUTPUT INSERTED.UserID, INSERTED.Username VALUES (@username, @email, @password, @emailVerified)');

            const user = result.recordset[0];
            await sendVerificationEmail(email, user.UserID);

            res.status(201).json({ id: user.UserID, username: user.Username, emailVerified: false });
        }
    } catch (err) {
        console.error('Register Error: ', err);
        res.status(500).send('Server error');
    }
};

module.exports.verifyEmail = async (req, res) => {
    const { token } = req.query;
    try {
        const decoded = jwt.verify(token, 'your_jwt_secret_here');
        const pool = await poolPromise;
        await pool.request()
            .input('userId', sql.Int, decoded.userId)
            .query('UPDATE [User] SET UserEmailVerified = 1 WHERE UserID = @userId');

        res.status(200).send('Email verified');
    } catch (err) {
        console.error('Email verification error:', err);
        res.status(500).send('Email verification failed');
    }
};

module.exports.logout = async (req, res) => {
    const { username } = req.body;
    console.log(`Logging out user: ${username}`);
    res.status(200).send('Logout successful');
};
