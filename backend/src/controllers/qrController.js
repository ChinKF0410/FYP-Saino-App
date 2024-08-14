const sql = require('mssql');
const crypto = require('crypto');
const QRCode = require('qrcode');
const dbConfig = require('../config/config');

// Initialize SQL connection pool
let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL');
        return pool; //notes: Return the pool object after successfully connecting to the database.
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1); //notes: Exit the process if the database connection fails.
    });

module.exports.generateQRCode = async (req, res) => {
    const { userID, PerID, EduBacID, CerID, IntelID, WorkExpID } = req.body; //notes: Destructure the relevant fields from the request body.

    try {
        const pool = await poolPromise; //notes: Wait for the database connection pool to be ready.

        // Step 1: Concatenate all data into a single string for hashing
        const dataString = `PerID=${PerID};EduBacID=${EduBacID};CerID=${CerID};IntelID=${IntelID};WorkExpID=${WorkExpID}`; 
        //notes: Combine various IDs into a single string for the purpose of creating a unique hash.

        // Step 2: Generate QR code hash
        const timestamp = Date.now().toString(); //notes: Generate a timestamp to include in the hash for uniqueness.
        const dataToHash = `${userID}:${timestamp}:${dataString}`; //notes: Combine userID, timestamp, and dataString into a single string to hash.
        const qrHash = crypto.createHash('sha256').update(dataToHash).digest('hex'); 
        //notes: Create a SHA-256 hash from the combined string to serve as the QR code identifier.

        // Step 3: Generate QR code image as a buffer
        const qrCodeBuffer = await QRCode.toBuffer(qrHash); //notes: Generate a QR code image from the hash and store it as a binary buffer.

        // Step 4: Insert the data into the QRPermission table
        const result = await pool.request()
            .input('userID', sql.Int, userID) //notes: Pass userID as an integer to the query.
            .input('PerID', sql.VarChar, PerID) //notes: Pass PerID as a varchar to the query.
            .input('EduBacIDs', sql.VarChar, EduBacID) //notes: Pass EduBacIDs as a varchar to the query.
            .input('CerIDs', sql.VarChar, CerID) //notes: Pass CerIDs as a varchar to the query.
            .input('IntelIDs', sql.VarChar, IntelID) //notes: Pass IntelIDs as a varchar to the query.
            .input('WorkExpIDs', sql.VarChar, WorkExpID) //notes: Pass WorkExpIDs as a varchar to the query.
            .input('QRHashCode', sql.VarChar, qrHash) //notes: Pass the generated QR hash as a varchar to the query.
            .input('QRCodeImage', sql.VarBinary, qrCodeBuffer) //notes: Pass the QR code image buffer as a varbinary to the query.
            .query(`
                INSERT INTO QRPermission 
                (UserID, PerID, EduBacIDs, CerIDs, IntelIDs, WorkExpIDs, QRHashCode, ExpireDate, QRCodeImage) 
                OUTPUT INSERTED.QRCodeImage
                VALUES (@userID, @PerID, @EduBacIDs, @CerIDs, @IntelIDs, @WorkExpIDs, @QRHashCode, DATEADD(DAY, 30, GETDATE()), @QRCodeImage);
            `); 
        //notes: Insert a new record into the QRPermission table and retrieve the QRCodeImage.

        // Step 5: Convert the binary QRCodeImage to a base64 string
        const qrCodeImageBase64 = result.recordset[0].QRCodeImage.toString('base64'); 
        //notes: Convert the QR code image from binary to a base64 string to send in the response.

        // Step 6: Respond with the base64 string of the QR code image
        res.status(201).json({
            qrHash, //notes: Include the generated QR hash in the response.
            qrCodeImage: qrCodeImageBase64 //notes: Include the base64-encoded QR code image in the response.
        });
    } catch (err) {
        console.error('QR Code Generation Error: ', err); //notes: Log any errors that occur during the QR code generation process.
        res.status(500).send('Server error'); //notes: Respond with a 500 status code if an error occurs.
    }
};


module.exports.searchQRCode = async (req, res) => {
    const { qrHashCode } = req.body; //notes: Extract the QR hash code from the request body.

    try {
        const pool = await poolPromise; //notes: Wait for the database connection pool to be ready.

        // Step 1: Query the QRPermission table using the QRHashCode
        const qrPermissionResult = await pool.request()
            .input('qrHashCode', sql.NVarChar, qrHashCode) //notes: Pass the QR hash code as an NVARCHAR to the query.
            .query(`
                SELECT * 
                FROM QRPermission 
                WHERE QRHashCode = @qrHashCode
                AND ExpireDate > GETDATE();
            `); 
        //notes: Query the QRPermission table for a record that matches the given QR hash code and hasn't expired.

        if (qrPermissionResult.recordset.length === 0) {
            return res.status(404).send('QR code not found or expired.'); //notes: Return a 404 error if the QR code is not found or has expired.
        }

        const qrPermissionData = qrPermissionResult.recordset[0]; //notes: Extract the first (and only) record from the query result.

        // Step 2: Clean and split the semicolon-separated IDs
        const splitIds = (idString) => {
            if (!idString) return []; //notes: Return an empty array if the input string is null or undefined.
            return idString
                .replace(/;$/, '') // Remove any trailing semicolon
                .split(';')        // Split by semicolons
                .map(id => id.trim()) // Trim any whitespace
                .filter(id => id !== ''); // Filter out any empty strings
            //notes: This function cleans and splits a semicolon-separated string into an array of IDs.
        };

        // Function to retrieve related data
        const fetchRelatedData = async (table, column, ids) => {
            const results = [];
            for (let id of ids) {
                // Cast ID to NVARCHAR to ensure proper SQL query execution
                const query = `SELECT * FROM ${table} WHERE CAST(${column} AS NVARCHAR) = @id`; 
                //notes: Cast the column to NVARCHAR to avoid type conversion issues when querying.
                const result = await pool.request()
                    .input('id', sql.NVarChar, id) //notes: Pass each ID as an NVARCHAR to the query.
                    .query(query);
                results.push(...result.recordset); //notes: Add the query results to the results array.
            }
            return results; //notes: Return the accumulated results from all the queries.
        };

        // Step 3: Retrieve related data based on the IDs
        const education = await fetchRelatedData('Education', 'EduBacID', splitIds(qrPermissionData.EduBacIDs));
        //notes: Fetch data from the Education table based on the EduBacIDs.
        const qualification = await fetchRelatedData('Qualification', 'CerID', splitIds(qrPermissionData.CerIDs));
        //notes: Fetch data from the Qualification table based on the CerIDs.
        const softSkill = await fetchRelatedData('SoftSkill', 'IntelID', splitIds(qrPermissionData.IntelIDs));
        //notes: Fetch data from the SoftSkill table based on the IntelIDs.
        const workExperience = await fetchRelatedData('Work', 'WorkExpID', splitIds(qrPermissionData.WorkExpIDs));
        //notes: Fetch data from the Work table based on the WorkExpIDs.
        const profile = qrPermissionData.PerID ? await fetchRelatedData('Profile', 'PerID',splitIds(qrPermissionData.PerID)): null;        //notes: Fetch data from the Profile table based on the PerID, if available.

        // Step 4: Combine all data into a single response object
        const responseData = {
            profile: profile ? profile[0] : null, //notes: Include the profile data in the response, if available.
            education: education, //notes: Include the education data in the response.
            qualification: qualification, //notes: Include the qualification data in the response.
            softSkill: softSkill, //notes: Include the soft skill data in the response.
            workExperience: workExperience, //notes: Include the work experience data in the response.
        };

        // Step 5: Send the response
        res.status(200).json(responseData); //notes: Respond with a 200 status code and the combined data.
    } catch (err) {
        console.error('QR Code Search Error: ', err); //notes: Log any errors that occur during the QR code search process.
        res.status(500).send('Server error'); //notes: Respond with a 500 status code if an error occurs.
    }
};
