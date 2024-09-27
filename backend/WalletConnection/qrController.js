const sql = require('mssql');
const crypto = require('crypto');
const QRCode = require('qrcode');
const dbConfig = require('./dbConfigWallet');

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
    const { userID, PerID, EduBacID, CerID, SoftID, WorkExpID } = req.body;

    try {
        const pool = await poolPromise;

        const dataString = `PerID=${PerID};EduBacID=${EduBacID};CerID=${CerID};SoftID=${SoftID};WorkExpID=${WorkExpID}`;
        const timestamp = Date.now().toString();
        const dataToHash = `${userID}:${timestamp}:${dataString}`;
        const qrHash = crypto.createHash('sha256').update(dataToHash).digest('hex');

        const qrCodeBuffer = await QRCode.toBuffer(qrHash);

        const result = await pool.request()
            .input('userID', sql.Int, userID)
            .input('PerID', sql.VarChar, PerID)
            .input('EduBacIDs', sql.VarChar, EduBacID)
            .input('CerIDs', sql.VarChar, CerID)
            .input('SoftIDs', sql.VarChar, SoftID)
            .input('WorkExpIDs', sql.VarChar, WorkExpID)
            .input('QRHashCode', sql.VarChar, qrHash)
            .input('QRCodeImage', sql.VarBinary, qrCodeBuffer)
            .query(`
                INSERT INTO QRPermission 
                (UserID, PerID, EduBacIDs, CerIDs, SoftIDs, WorkExpIDs, QRHashCode, ExpireDate, QRCodeImage) 
                OUTPUT INSERTED.QRCodeImage
                VALUES (@userID, @PerID, @EduBacIDs, @CerIDs, @SoftIDs, @WorkExpIDs, @QRHashCode, DATEADD(DAY, 30, GETDATE()), @QRCodeImage);
            `);

        const qrCodeImageBase64 = result.recordset[0].QRCodeImage.toString('base64');

        res.status(201).json({
            qrHash,
            qrCodeImage: qrCodeImageBase64
        });
    } catch (err) {
        console.error('QR Code Generation Error: ', err);
        res.status(500).send('Server error');
    }
};

const formatDate = (datetime) => {
    if (!datetime) return null;
    const date = new Date(datetime);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
};

module.exports.searchQRCode = async (req, res) => {
    const { qrHashCode } = req.body;

    try {
        const pool = await poolPromise;

        // Check the input data
        console.log(`Searching for QR code: ${qrHashCode}`);

        const qrPermissionResult = await pool.request()
            .input('qrHashCode', sql.NVarChar, qrHashCode)
            .query(`
                SELECT * 
                FROM QRPermission 
                WHERE QRHashCode = @qrHashCode
                AND ExpireDate > GETDATE();
            `);

        if (qrPermissionResult.recordset.length === 0) {
            console.log('QR code not found or expired.');
            return res.status(404).send('QR code not found or expired.');
        }

        const qrPermissionData = qrPermissionResult.recordset[0];
        console.log(`QR Permission Data:`, qrPermissionData);

        const splitIds = (idString) => {
            if (!idString) return [];
            return idString.replace(/;$/, '').split(';').map(id => id.trim()).filter(id => id !== '');
        };

        const fetchRelatedData = async (table, column, ids) => {
            const results = [];
            for (let id of ids) {
                const query = `SELECT * FROM ${table} WHERE CAST(${column} AS NVARCHAR) = @id`;
                console.log(`Fetching from ${table} for ID: ${id}`); // Log query
                const result = await pool.request()
                    .input('id', sql.NVarChar, id)
                    .query(query);
                console.log(`Result from ${table}:`, result.recordset);
                results.push(...result.recordset);
            }
            return results;
        };

        const education = await fetchRelatedData('Education', 'EduBacID', splitIds(qrPermissionData.EduBacIDs));
        const qualification = await fetchRelatedData('Certification', 'CerID', splitIds(qrPermissionData.CerIDs));
        const skills = await fetchRelatedData('SoftSkill', 'SoftID', splitIds(qrPermissionData.SoftIDs));
        const workExperience = await fetchRelatedData('Work', 'WorkExpID', splitIds(qrPermissionData.WorkExpIDs));
        const profile = qrPermissionData.PerID ? await fetchRelatedData('Profile', 'PerID', splitIds(qrPermissionData.PerID)) : null;

        console.log('Skills:', skills); // Log skills
        console.log('workExperience:', workExperience); // Log education
        
        const responseData = {
            profile: profile ? profile[0] : null,
            education,
            qualification,
            skills,
            workExperience,
        };

        res.status(200).json(responseData);
    } catch (err) {
        console.error('QR Code Search Error: ', err);
        res.status(500).send('Server error');
    }
};


module.exports.fetchQRCodesByUserId = async (req, res) => {
    const { userID } = req.body;

    try {
        const pool = await poolPromise;

        const qrCodesResult = await pool.request()
            .input('userID', sql.Int, userID)
            .query(`
                SELECT QRHashCode, QRCodeImage, ExpireDate 
                FROM QRPermission 
                WHERE UserID = @userID AND ExpireDate > GETDATE()
            `);

        if (qrCodesResult.recordset.length === 0) {
            return res.status(404).send('No active QR codes found for this user.');
        }

        const qrCodes = qrCodesResult.recordset.map(record => ({
            qrHashCode: record.QRHashCode,
            qrCodeImage: record.QRCodeImage.toString('base64'),
            expireDate: record.ExpireDate.toISOString() // Format date as ISO string
        }));

        res.status(200).json({ qrCodes });
    } catch (err) {
        console.error('Fetch QR Codes by UserID Error:', err);
        res.status(500).send('Server error');
    }
};
