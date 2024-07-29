const sql = require('mssql');
const bcrypt = require('bcryptjs');
const dbConfig = require('../config/config');

let poolPromise;

(async () => {
    try {
        poolPromise = sql.connect(dbConfig);
        console.log('Connected to MSSQL');
    } catch (err) {
        console.error('Database Connection Failed! Bad Config: ', err);
    }
})();

module.exports.login = async (req, res) => {
    const { email, password } = req.body;
    console.log(`Login attempt with email: ${email}`);
    try {
        const pool = await poolPromise;
        // Optimize the query to fetch only necessary fields, not all
        const result = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT UserID, Password FROM [User] WHERE Email = @email');

        console.log('Query result:', result);

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            console.log('User found:', user);
            // Directly compare passwords
            if (await bcrypt.compare(password, user.Password)) {
                console.log('Password valid');
                res.status(200).json({ id: user.UserID });
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
    console.log(`Register attempt with email: ${email}`);
    try {
        const pool = await poolPromise;
        // Check for existing user with the same email
        const checkUser = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT UserID FROM [User] WHERE Email = @email');

        if (checkUser.recordset.length > 0) {
            res.status(400).send('Email already in use');
        } else {
            const hashedPassword = await bcrypt.hash(password, 10);
            // Insert user with minimal and required fields only
            const result = await pool.request()
                .input('username', sql.VarChar, username)
                .input('email', sql.VarChar, email)
                .input('password', sql.VarChar, hashedPassword)
                .input('emailVerified', sql.Bit, 0)
                .query('INSERT INTO [User] (Username, Email, Password, UserEmailVerified) OUTPUT INSERTED.UserID VALUES (@username, @email, @password, @emailVerified)');

            console.log('User registered:', result);
            res.status(201).json({ id: result.recordset[0].UserID });
        }
    } catch (err) {
        console.error('Register Error: ', err);
        res.status(500).send('Server error');
    }
};

