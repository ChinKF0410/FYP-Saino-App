const sql = require('mssql');
const bcrypt = require('bcryptjs');
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
            .query('SELECT UserID, Username, Password FROM [User] WHERE Email = @email');
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
                });
            } else {
                res.status(401).send('Invalid email or password');
            }
        } else {
            res.status(401).send('Invalid email or password');
        }
    } catch (err) {
        console.error('Login Error1: ', err);
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
                .query('INSERT INTO [User] (Username, Email, Password) OUTPUT INSERTED.UserID, INSERTED.Username VALUES (@username, @email, @password)');

            const user = result.recordset[0];

            res.status(201).json({ id: user.UserID, username: user.Username });
        }
    } catch (err) {
        console.error('Register Error: ', err);
        res.status(500).send('Server error');
    }
};


module.exports.logout = async (req, res) => {
    const { username } = req.body;
    console.log(`Logging out user: ${username}`);
    res.status(200).send('Logout successful');
};

module.exports.verifyPassword = async (req, res) => {
    const { email, password } = req.body;
    console.log(`Password verification attempt for: ${email}`);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT Password FROM [User] WHERE Email = @email');

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            const isPasswordValid = await bcrypt.compare(password, user.Password);

            if (isPasswordValid) {
                res.status(200).send('Password verified');
            } else {
                res.status(401).send('Incorrect password');
            }
        } else {
            res.status(404).send('User not found');
        }
    } catch (err) {
        console.error('Error verifying password:', err);
        res.status(500).send('Server error');
    }
};

module.exports.changePassword = async (req, res) => {
    const { email, oldPassword, newPassword } = req.body;
    console.log(`Password change attempt for: ${email}`);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT Password FROM [User] WHERE Email = @email');

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            const isPasswordValid = await bcrypt.compare(oldPassword, user.Password);

            if (isPasswordValid) {
                const hashedNewPassword = await bcrypt.hash(newPassword, 10);
                await pool.request()
                    .input('email', sql.VarChar, email)
                    .input('newPassword', sql.VarChar, hashedNewPassword)
                    .query('UPDATE [User] SET Password = @newPassword WHERE Email = @email');

                res.status(200).send('Password updated successfully');
            } else {
                res.status(401).send('Incorrect old password');
            }
        } else {
            res.status(404).send('User not found');
        }
    } catch (err) {
        console.error('Error changing password:', err);
        res.status(500).send('Server error');
    }
};


module.exports.getProfile = async (req, res) => {
    const { userID } = req.body;

    if (!userID) {
        return res.status(400).send({ message: "userID is required" });
    }

    try {
        const pool = await poolPromise;

        const result = await pool.request()
            .input('userID', sql.Int, userID)
            .query(`
          SELECT Nickname, Surname, Lastname, Age, MobilePhone, ProfilePic
          FROM User_Profile
          WHERE UserID = @userID
        `);

        if (result.recordset.length === 0) {
            return res.status(404).send({ message: "Profile not found" + userID });
        }

        const profile = result.recordset[0];
        if (profile.ProfilePic) {
            profile.Photo = Buffer.from(profile.ProfilePic).toString('base64');
        }
        res.status(200).send(profile);
    } catch (error) {
        res.status(500).send({ message: "Error fetching profile", error });
    }
};

// Save or update profile details
module.exports.saveProfile = async (req, res) => {
    const { userID, nickname, surname, lastname, age, mobilePhone, photo } = req.body;

    if (!userID || !nickname || !surname || !lastname || !mobilePhone || age == null) {
        return res.status(400).send({ message: "All fields are required" });
    }

    try {
        const pool = await poolPromise;

        const profilePicBuffer = photo ? Buffer.from(photo, 'base64') : null;
        await pool.request()
            .input('userID', sql.Int, userID)
            .input('nickname', sql.VarChar(255), nickname)
            .input('surname', sql.VarChar(255), surname)
            .input('lastname', sql.VarChar(255), lastname)
            .input('age', sql.Int, age)
            .input('mobilePhone', sql.VarChar(255), mobilePhone)
            .input('profilePic', sql.VarBinary(sql.MAX), profilePicBuffer)
            .query(`
            IF EXISTS (SELECT 1 FROM User_Profile WHERE UserID = @userID)
            BEGIN
                UPDATE User_Profile
                SET Nickname = @nickname,
                    Surname = @surname,
                    Lastname = @lastname,
                    Age = @age,
                    MobilePhone = @mobilePhone,
                    ProfilePic = @profilePic
                WHERE UserID = @userID;
            END
            ELSE
            BEGIN
                INSERT INTO User_Profile (UserID, Nickname, Surname, Lastname, Age, MobilePhone, ProfilePic)
                VALUES (@userID, @nickname, @surname, @lastname, @age, @mobilePhone, @profilePic);
            END
        `);

        res.status(200).send({ message: "Profile updated successfully" });
    } catch (error) {
        res.status(500).send({ message: "Error updating profile", error });
    }
};