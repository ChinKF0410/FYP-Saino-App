/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

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

// Login function
module.exports.login = async (req, res) => {
    const { email, password } = req.body;
    console.log(`Login attempt with email: ${email}`);

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT UserID, UserRoleID, Username, Password, isVerified FROM [User] WHERE Email = @email');
        console.log('Query result:', result);

        // Check if user exists
        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            console.log('User found:', user);
            console.log("ISVERIFIED: ", user.isVerified);
            // Check if user is verified
            if (user.isVerified === 0) {
                console.log("WHY");
                return res.status(402).send('The Email is Not Verified');

            } else if (user.isVerified === 2) {
                return res.status(403).send('REJECTED.');
            }
            console.log("WHY2");

            // Compare the provided password with the stored hashed password
            const isPasswordValid = await bcrypt.compare(password, user.Password);
            console.log('Password valid:', isPasswordValid);

            // If password is valid, return user details
            if (isPasswordValid) {
                if (user.isVerified === 1) {
                    return res.status(201).json({
                        id: user.UserID,
                        username: user.Username,
                        userRoleID: user.UserRoleID  // Ensure the field name matches the column in the database
                    });
                } else {
                    return res.status(200).json({
                        id: user.UserID,
                        username: user.Username,
                        userRoleID: user.UserRoleID  // Ensure the field name matches the column in the database
                    });
                }
            } else {
                return res.status(401).send('Invalid email or password');
            }
        } else {
            return res.status(401).send('Invalid email or password');
        }
    } catch (err) {
        console.error('Login Error: ', err);
        return res.status(500).send('Server error');
    }
};

// Register function
module.exports.register = async (req, res) => {
    const { username, email, password, companyname } = req.body;
    const userRoleID = 2; //assume 2 is company
    const isVerified = 0; // Assume 0 means not verified yet

    try {
        const pool = await poolPromise;
        const userExists = await pool.request()
            .input('email', sql.VarChar, email)
            .query('SELECT UserID FROM [User] WHERE Email = @email');

        // Check if the email is already in use
        if (userExists.recordset.length > 0) {
            return res.status(400).send('Email already in use');
        } else {
            // Hash the password and insert the new user
            const hashedPassword = await bcrypt.hash(password, 10);
            const result = await pool.request()
                .input('username', sql.VarChar, username)
                .input('email', sql.VarChar, email)
                .input('companyname', sql.VarChar, companyname)
                .input('userRoleID', sql.Int, userRoleID)
                .input('isVerified', sql.Int, isVerified)
                .input('password', sql.VarChar, hashedPassword)
                .query('INSERT INTO [User] (Username, UserRoleID, Email, Password, isVerified, CompanyName) OUTPUT INSERTED.UserID, INSERTED.Username VALUES (@username, @userRoleID, @email, @password, @isVerified, @companyname)');

            const user = result.recordset[0];

            // Return the newly created user details
            return res.status(201).json({ id: user.UserID, username: user.Username });
        }
    } catch (err) {
        console.error('Register Error: ', err);
        return res.status(500).send('Server error');
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

    // Validate required fields
    if (!userID || !nickname || !surname || !lastname || !mobilePhone || age == null) {
        return res.status(400).send({ message: "All fields are required" });
    }

    // Validate mobilePhone: must start with '01' and be 10 or 11 digits long
    const mobilePhoneRegex = /^01\d{8,9}$/;
    if (!mobilePhoneRegex.test(mobilePhone)) {
        return res.status(400).send({ message: "Invalid Mobile Phone Number. " });
    }

    // Validate age: must be between 0 and 99
    if (isNaN(age) || age < 0 || age > 99) {
        return res.status(400).send({ message: "Invalid Age." });
    }

    try {
        const pool = await poolPromise;

        const profilePicBuffer = photo ? Buffer.from(photo, 'base64') : null;

        const result = await pool.request()
            .input('userID', sql.Int, userID)
            .input('nickname', sql.VarChar(255), nickname)
            .input('surname', sql.VarChar(255), surname)
            .input('lastname', sql.VarChar(255), lastname)
            .input('age', sql.Int, age)
            .input('mobilePhone', sql.VarChar(255), mobilePhone)
            .input('profilePic', sql.VarBinary(sql.MAX), profilePicBuffer)
            .query(`
            DECLARE @InsertedProfile TABLE (ProfileID INT);
    
            IF EXISTS (SELECT 1 FROM User_Profile WHERE UserID = @userID)
            BEGIN
                -- Update User_Profile if record exists
                UPDATE User_Profile
                SET Nickname = @nickname,
                    Surname = @surname,
                    Lastname = @lastname,
                    Age = @age,
                    MobilePhone = @mobilePhone,
                    ProfilePic = @profilePic
                WHERE UserID = @userID;
    
                -- Get the existing ProfileID for this UserID
                INSERT INTO @InsertedProfile (ProfileID)
                SELECT ProfileID
                FROM User_Profile
                WHERE UserID = @userID;
            END
            ELSE
            BEGIN
                -- Insert into User_Profile if record doesn't exist and capture ProfileID
                INSERT INTO User_Profile (UserID, Nickname, Surname, Lastname, Age, MobilePhone, ProfilePic)
                OUTPUT INSERTED.ProfileID INTO @InsertedProfile (ProfileID) -- Capture the ProfileID of the inserted row
                VALUES (@userID, @nickname, @surname, @lastname, @age, @mobilePhone, @profilePic);
            END
    
            -- Now update UserProID in User table with the ProfileID
            UPDATE [User]
            SET UserProID = (SELECT ProfileID FROM @InsertedProfile)
            WHERE UserID = @userID;
    
            -- Return the ProfileID
            SELECT ProfileID FROM @InsertedProfile;
        `);

        const profileID = result.recordset[0].ProfileID; // Get the ProfileID from the result


        res.status(200).send({ message: "Profile updated successfully" });
    } catch (error) {
        console.log(error);
        res.status(500).send({ message: "Error updating profile", error });
    }
};



module.exports.saveFeedback = async (req, res) => {
    const { userID, username, userEmail, title, description } = req.body;
    console.log("saveFeedBack Working");
    // Validate required fields
    console.log(userID);

    console.log(username);

    console.log(userEmail);

    console.log(title);

    console.log(description);

    if (!userID || !username || !userEmail || !title || !description) {
        return res.status(400).send({ message: "All fields are required" });
    }
    console.log("Checked Input");

    try {
        const pool = await poolPromise;

        // Insert or update the feedback in the database
        console.log("calling database");

        await pool.request()
            .input('userID', sql.Int, userID)
            .input('username', sql.NVarChar(255), username)
            .input('userEmail', sql.NVarChar(255), userEmail)
            .input('title', sql.NVarChar(255), title)
            .input('description', sql.NVarChar(sql.MAX), description)
            .query(`
            IF EXISTS (SELECT 1 FROM Feedback WHERE UserID = @userID AND Title = @title)
            BEGIN
                UPDATE Feedback
                SET Description = @description,
                    Username = @username,
                    UserEmail = @userEmail
                WHERE UserID = @userID AND Title = @title;
            END
            ELSE
            BEGIN
                INSERT INTO Feedback (UserID, Username, UserEmail, Title, Description)
                VALUES (@userID, @username, @userEmail, @title, @description);
            END
        `);
        console.log("saveFeedBack Success");

        res.status(200).send({ message: "Feedback submitted successfully" });
    } catch (error) {
        console.log("saveFeedBack Fail");
        console.log(error);
        res.status(500).send({ message: "Error submitting feedback", error });
    }
};