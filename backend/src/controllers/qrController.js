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


module.exports.searchQRCode = async (req, res) => {
    const { qrHashCode } = req.body;

    try {
        const pool = await poolPromise;

        // Step 1: Query the QRPermission table using the QRHashCode
        const qrPermissionResult = await pool.request()
            .input('qrHashCode', sql.NVarChar, qrHashCode)
            .query(`
                SELECT * 
                FROM QRPermission 
                WHERE QRHashCode = @qrHashCode
                AND ExpireDate > GETDATE();
            `);

        if (qrPermissionResult.recordset.length === 0) {
            return res.status(404).send('QR code not found or expired.');
        }

        const qrPermissionData = qrPermissionResult.recordset[0];

        // Step 2: Clean and split the semicolon-separated IDs
        const splitIds = (idString) => {
            if (!idString) return [];
            return idString
                .replace(/;$/, '') // Remove any trailing semicolon
                .split(';')        // Split by semicolons
                .map(id => id.trim()) // Trim any whitespace
                .filter(id => id !== ''); // Filter out any empty strings
        };

        // Function to retrieve related data
        const fetchRelatedData = async (table, column, ids) => {
            const results = [];
            for (let id of ids) {
                // Cast ID to NVARCHAR to ensure proper SQL query execution
                const query = `SELECT * FROM ${table} WHERE CAST(${column} AS NVARCHAR) = @id`;
                const result = await pool.request()
                    .input('id', sql.NVarChar, id)
                    .query(query);
                results.push(...result.recordset);
            }
            return results;
        };

        // Step 3: Retrieve related data based on the IDs
        const education = await fetchRelatedData('Education', 'EduBacID', splitIds(qrPermissionData.EduBacIDs));
        const qualification = await fetchRelatedData('Qualification', 'CerID', splitIds(qrPermissionData.CerIDs));
        const softSkill = await fetchRelatedData('SoftSkill', 'IntelID', splitIds(qrPermissionData.IntelIDs));
        const workExperience = await fetchRelatedData('Work', 'WorkExpID', splitIds(qrPermissionData.WorkExpIDs));
        const profile = qrPermissionData.PerID ? await fetchRelatedData('Profile', 'PerID', [qrPermissionData.PerID]) : null;

        // Step 4: Combine all data into a single response object
        const responseData = {
            profile: profile ? profile[0] : null,
            education: education,
            qualification: qualification,
            softSkill: softSkill,
            workExperience: workExperience,
            qrPermission: qrPermissionData  // Include the original QRPermission data
        };

        // Step 5: Send the response
        res.status(200).json(responseData);
    } catch (err) {
        console.error('QR Code Search Error: ', err);
        res.status(500).send('Server error');
    }
};