const fetch = require('node-fetch'); // Add this at the top to import node-fetch
const sql = require('mssql');
sql.globalConnectionPool = false;
const dbConfigWallet = require('../config/config');

// Initialize SQL connection pool
let poolPromise = new sql.connect(dbConfigWallet)
    .then(pool => {
        console.log('Connected to MSSQL Wallet DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });
module.exports.saveCVCertification = async (req, res) => {
    const { accountID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate } = req.body;
    // Validate input
    console.log("CALL SAVE");
    if (!accountID) {
        console.log("CALL SAVE1");

        return res.status(400).send('Account ID is required');
    }
    if (!CerName || !CerIssuer || !CerAcquiredDate) {
        console.log("CALL SAVE2");

        return res.status(400).send('Certification Name, Issuer, and Acquired Date are required');
    }

    try {
        const pool = await poolPromise;
        console.log("CALL SAVE3");

        // Insert new certification into the Certification table
        const result = await pool.request()
            .input('UserID', sql.Int, accountID)
            .input('CerName', sql.NVarChar(50), CerName)
            .input('CerEmail', sql.NVarChar(50), CerEmail)
            .input('CerType', sql.NVarChar(50), CerType)
            .input('CerIssuer', sql.NVarChar(50), CerIssuer)
            .input('CerDescription', sql.NVarChar(200), CerDescription)
            .input('CerAcquiredDate', sql.DateTime, CerAcquiredDate)
            .query(`
                INSERT INTO Certification (UserID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate)
                OUTPUT INSERTED.CerID
                VALUES (@UserID, @CerName, @CerEmail, @CerType, @CerIssuer, @CerDescription, @CerAcquiredDate)
            `);
        console.log("CALL SAVE4");

        // Return the new CerID along with a success message
        res.status(200).json({
            message: 'Certification saved successfully',
            CerID: result.recordset[0].CerID,
            CerName,
            CerEmail,
            CerType,
            CerIssuer,
            CerDescription,
            CerAcquiredDate,

        });
        console.log("storeCredentialToDBSuccess");
    } catch (error) {
        console.error('Error saving certification:', error.message);
        res.status(500).send('Server error');
    }
};



module.exports.deleteCVCertification = async (req, res) => {
    const { accountID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CertificationAcquireDate } = req.body;
    console.log("CALL DELETE");
    if (!accountID) {
        console.log("Error");


        return res.status(400).json({ message: 'Missing required fields' });
    }


    if (!CerName || !CerEmail  || !CertificationAcquireDate) {
        console.log("Error2");
        console.log(CerName); 
        console.log(CerIssuer);
        console.log(CertificationAcquireDate);
        return res.status(400).json({ message: 'Missing certification details' });
    }

    try {
        const pool = await poolPromise;

        await pool.request()
            .input('UserID', sql.Int, accountID)
            .input('CerName', sql.NVarChar, CerName)
            .input('CerEmail', sql.NVarChar, CerEmail)
            .input('CerAcquiredDate', sql.DateTime, CertificationAcquireDate)
            .query(`
          DELETE FROM Certification
          WHERE UserID = @UserID
          AND CerName = @CerName
          AND CerEmail = @CerEmail
          AND CerAcquiredDate = @CerAcquiredDate
        `);
        console.log("Done");

        res.status(200).json({ message: 'Certification deleted successfully' });
    } catch (error) {
        console.error('Error deleting certification:', error);
        res.status(500).json({ message: 'Internal Server Error' });
    }

};




module.exports.updateCVCertification = async (req, res) => {
    const { accountID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CertificationAcquireDate } = req.body;

    // Validate input
    console.log("Starting certification save...");
    if (!accountID) {
        console.log("Account ID is missing");
        return res.status(400).send('Account ID is required');
    }
    if (!CerName || !CerIssuer || !CertificationAcquireDate) {
        console.log(CerName); console.log(CerIssuer);
        console.log(CertificationAcquireDate);

        console.log("Certification Name, Issuer, or Acquired Date missing");
        return res.status(400).send('Certification Name, Issuer, and Acquired Date are required');
    }

    try {
        const pool = await poolPromise;

        console.log("Inserting certification data into the database...");

        // Insert new certification into the Certification table
        const result = await pool.request()
            .input('UserID', sql.Int, accountID)
            .input('CerName', sql.NVarChar(50), CerName)
            .input('CerEmail', sql.NVarChar(50), CerEmail)
            .input('CerType', sql.NVarChar(50), CerType)
            .input('CerIssuer', sql.NVarChar(50), CerIssuer)
            .input('CerDescription', sql.NVarChar(200), CerDescription)
            .input('CerAcquiredDate', sql.DateTime, CertificationAcquireDate)
            .query(`
                INSERT INTO Certification (UserID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate)
                OUTPUT INSERTED.CerID
                VALUES (@UserID, @CerName, @CerEmail, @CerType, @CerIssuer, @CerDescription, @CerAcquiredDate)
            `);

        console.log("Certification saved successfully");

        // Return the new CerID along with a success message
        res.status(200).json({
            message: 'Certification saved successfully',
            CerID: result.recordset[0].CerID,
            CerName,
            CerEmail,
            CerType,
            CerIssuer,
            CerDescription,
            CertificationAcquireDate,
        });

        console.log("Certification save operation completed.");
    } catch (error) {
        console.error('Error saving certification:', error.message);
        res.status(500).send('Server error');
    }
};
