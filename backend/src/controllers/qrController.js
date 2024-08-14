const sql = require('mssql');
const crypto = require('crypto');
const QRCode = require('qrcode');
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

module.exports.generateQRCode = async (req, res) => {
    const { userID, PerID, EduBacID, CerID, IntelID, WorkExpID } = req.body;

    try {
        const pool = await poolPromise;

        // Step 1: Concatenate all data into a single string for hashing
        const dataString = `PerID=${PerID};EduBacID=${EduBacID};CerID=${CerID};IntelID=${IntelID};WorkExpID=${WorkExpID}`;

        // Step 2: Generate QR code hash
        const timestamp = Date.now().toString();
        const dataToHash = `${userID}:${timestamp}:${dataString}`;
        const qrHash = crypto.createHash('sha256').update(dataToHash).digest('hex');

        // Step 3: Generate QR code image as a buffer
        const qrCodeBuffer = await QRCode.toBuffer(qrHash);

        // Step 4: Insert the data into the QRPermission table
        const result = await pool.request()
            .input('userID', sql.Int, userID)
            .input('PerID', sql.VarChar, PerID)
            .input('EduBacIDs', sql.VarChar, EduBacID)
            .input('CerIDs', sql.VarChar, CerID)
            .input('IntelIDs', sql.VarChar, IntelID)
            .input('WorkExpIDs', sql.VarChar, WorkExpID)
            .input('QRHashCode', sql.VarChar, qrHash)
            .input('QRCodeImage', sql.VarBinary, qrCodeBuffer)
            .query(`
                INSERT INTO QRPermission 
                (UserID, PerID, EduBacIDs, CerIDs, IntelIDs, WorkExpIDs, QRHashCode, ExpireDate, QRCodeImage) 
                OUTPUT INSERTED.QRCodeImage
                VALUES (@userID, @PerID, @EduBacIDs, @CerIDs, @IntelIDs, @WorkExpIDs, @QRHashCode, DATEADD(DAY, 30, GETDATE()), @QRCodeImage);
            `);

        // Step 5: Convert the binary QRCodeImage to a base64 string
        const qrCodeImageBase64 = result.recordset[0].QRCodeImage.toString('base64');

        // Step 6: Respond with the base64 string of the QR code image
        res.status(201).json({
            qrHash,
            qrCodeImage: qrCodeImageBase64
        });
    } catch (err) {
        console.error('QR Code Generation Error: ', err);
        res.status(500).send('Server error');
    }
};
