const sql = require('mssql');
const dbConfig = require('../config/config');
sql.globalConnectionPool = false;

let poolPromise = sql.connect(dbConfig)
    .then(pool => {
        console.log('Connected to MSSQL SAINO DB');
        return pool;
    })
    .catch(err => {
        console.error('Database Connection Failed! Bad Config: ', err);
        process.exit(1);
    });



//Profile ----------

module.exports.saveCVProfile = async (req, res) => {
    const { accountID, Photo, name, age, email_address, mobile_number, address, description, PerID } = req.body;

    try {
        console.log("Start saving profile to the second database");

        // Fetch the connection pool for the second database
        const secondPool = await poolPromise;  // Assuming you have a separate connection for the second database

        // Convert base64 Photo to binary buffer
        const profilePicBuffer = Photo ? Buffer.from(Photo, 'base64') : null;
        console.log(profilePicBuffer);

        // Execute SQL query to save or update the profile in the second database
        await secondPool.request()
            .input('StudentAccID', sql.Int, accountID)
            .input('RefID', sql.Int, PerID)  // PerID passed from the first API
            .input('Photo', sql.VarBinary(sql.MAX), profilePicBuffer)
            .input('Name', sql.NVarChar, name)
            .input('Age', sql.NVarChar, age)
            .input('Email_Address', sql.NVarChar, email_address)
            .input('Mobile_Number', sql.NVarChar, mobile_number)
            .input('Address', sql.NVarChar, address)
            .input('Description', sql.NVarChar, description)
            .query(`
                IF EXISTS (SELECT 1 FROM Profile WHERE StudentAccID = @StudentAccID)
                BEGIN
                    UPDATE Profile
                    SET Photo = @Photo, Name = @Name, Age = @Age, Email_Address = @Email_Address, 
                        Mobile_Number = @Mobile_Number, Address = @Address, Description = @Description, RefID = @RefID
                    WHERE StudentAccID = @StudentAccID
                END
                ELSE
                BEGIN
                    INSERT INTO Profile (StudentAccID, RefID, Photo, Name, Age, Email_Address, Mobile_Number, Address, Description)
                    VALUES (@StudentAccID, @RefID, @Photo, @Name, @Age, @Email_Address, @Mobile_Number, @Address, @Description)
                END
            `);

        console.log("Profile saved successfully to the second database");

        // Return success response
        return res.status(200).send('Profile saved successfully to the second database.');

    } catch (error) {
        console.error('Error saving profile to the second database:', error);

        // Return error response
        return res.status(500).send('Failed to save profile to the second database.');
    }
};


//SoftSkills ----------

module.exports.saveCVSkill = async (req, res) => {


    const { accountID, skillEntries } = req.body;

    console.log(req.body);
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }

    try {
        const sainoPool = await poolPromise;
        if (skillEntries && skillEntries.length > 0) {

            // Process existing skill entries (updates or deletes)
            for (const skill of skillEntries) {
                const { SoftID, SoftHighlight, SoftDescription, isPublic } = skill;

                console.log("SoftID:  " + SoftID);
                console.log("SoftHighlight:  " + SoftHighlight);
                console.log("SoftDescription:  " + SoftDescription);
                console.log("isPublic:  " + isPublic);
                console.log("accountID:  " + accountID);


                if (isPublic === false) {
                    await module.exports.deleteCVSkill({
                        body: { SoftID }
                    }, {
                        status: (code) => ({
                            json: (message) => console.log(`Delete status: ${code}, message: ${JSON.stringify(message)}`)
                        })
                    });
                } else {
                    // Update the existing skill if isPublic is true
                    await sainoPool.request()
                        .input('SoftID', sql.Int, SoftID) // This will be used for RefID
                        .input('SoftHighlight', sql.NVarChar, SoftHighlight)
                        .input('SoftDescription', sql.NVarChar, SoftDescription)
                        .input('StudentAccID', sql.Int, accountID) // Assuming accountID is StudentAccID
                        .query(`
                        IF EXISTS (SELECT 1 FROM SoftSkill WHERE RefID = @SoftID)
                        BEGIN
                            -- Update the skill entry if RefID matches SoftID
                            UPDATE SoftSkill
                            SET SoftHighlight = @SoftHighlight, SoftDescription = @SoftDescription
                            WHERE RefID = @SoftID
                        END
                        ELSE
                        BEGIN
                            -- Insert the skill entry if it doesn't exist
                            INSERT INTO SoftSkill (RefID, StudentAccID, SoftHighlight, SoftDescription)
                            VALUES (@SoftID, @StudentAccID, @SoftHighlight, @SoftDescription)
                        END
                    `);


                }
            }
        }
        // Sending success response after all operations are complete
        res.status(200).send('SoftSkill saved successfully');

    } catch (e) {
        console.error('Error saving skills:', e.message);
        res.status(500).send('Server error');
    }
};

module.exports.deleteCVSkill = async (req, res) => {
    const { SoftID } = req.body;

    // Validate input
    if (!SoftID) {
        return res.status(400).json({ message: 'SoftID is required' });
    }

    try {
        const sainoPool = await poolPromise;

        // Attempt to delete the skill using SoftID as RefID
        const result = await sainoPool.request()
            .input('RefID', sql.Int, SoftID) // Use SoftID as RefID
            .query(`
                DELETE FROM SoftSkill
                WHERE RefID = @RefID
            `);

        // Check if any rows were affected (i.e., a skill was deleted)
        if (result.rowsAffected[0] > 0) {
            // Return 200 status code for successful deletion
            return res.status(200).json({ message: 'Skill deleted successfully' });
        } else {
            // Return 404 status code if no matching entry was found
            return res.status(201).json({ message: 'Skill not found' });
        }
    } catch (error) {
        console.error('Error deleting skill:', error.message);
        res.status(500).json({ message: 'Server error while deleting skill' });
    }
};


//Work Experience ----------

module.exports.saveCVWork = async (req, res) => {
    const { accountID, workEntries } = req.body;

    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    console.log("Checked Work");

    try {
        const pool = await poolPromise;

        // Process existing entries (check for update or delete)
        if (workEntries && workEntries.length > 0) {
            console.log("Inside existing");

            for (let entry of workEntries) {
                const {
                    WorkExpID, job_title, company_name, industry, country, state, city, description, start_date, end_date, isPublic
                } = entry;
                console.log("existing 1");
                console.log(WorkExpID);
                console.log("==========================");

                if (isPublic === false) {
                    console.log("existing ispublic false");
                    console.log(WorkExpID);
                    console.log("11111111111111111111111111111111");
                    await module.exports.deleteCVWork({
                        body: { WorkExpID }
                    }, {
                        status: (code) => ({
                            json: (message) => console.log(`Delete status: ${code}, message: ${JSON.stringify(message)}`)
                        })
                    });
                } else {
                    console.log("isPublic is TRUE");
                    // Log the input parameters for debugging
                    console.log('WorkExpID:', WorkExpID);
                    console.log('WorkTitle:', job_title);
                    console.log('WorkCompany:', company_name);
                    console.log('WorkIndustry:', industry);
                    console.log('WorkCountry:', country);
                    console.log('WorkState:', state);
                    console.log('WorkCity:', city);
                    console.log('WorkDescription:', description);
                    console.log('WorkStartDate:', start_date);
                    console.log('WorkEndDate:', end_date);

                    try {
                        const result = await pool.request()
                            .input('WorkExpID', sql.Int, WorkExpID) // This will be used for RefID
                            .input('StudentAccID', sql.Int, accountID) // Assuming accountID is StudentAccID
                            .input('WorkTitle', sql.NVarChar, job_title)
                            .input('WorkCompany', sql.NVarChar, company_name)
                            .input('WorkIndustry', sql.NVarChar, industry)
                            .input('WorkCountry', sql.NVarChar, country)
                            .input('WorkState', sql.NVarChar, state)
                            .input('WorkCity', sql.NVarChar, city)
                            .input('WorkDescription', sql.NVarChar, description)
                            .input('WorkStartDate', sql.NVarChar, start_date)
                            .input('WorkEndDate', sql.NVarChar, end_date)
                            .query(`
            IF EXISTS (
                SELECT 1 FROM Work 
                WHERE RefID = @WorkExpID
            )
            BEGIN
                -- Update the work entry if RefID matches WorkExpID
                UPDATE Work
                SET WorkIndustry = @WorkIndustry, WorkCountry = @WorkCountry, WorkState = @WorkState,
                    WorkCity = @WorkCity, WorkDescription = @WorkDescription, WorkStartDate = @WorkStartDate,
                    WorkEndDate = @WorkEndDate
                WHERE RefID = @WorkExpID
            END
            ELSE
            BEGIN
                -- Insert the work entry if it doesn't exist
                INSERT INTO Work (RefID, StudentAccID, WorkTitle, WorkCompany, WorkIndustry, WorkCountry, 
                    WorkState, WorkCity, WorkDescription, WorkStartDate, WorkEndDate)
                VALUES (@WorkExpID, @StudentAccID, @WorkTitle, @WorkCompany, @WorkIndustry, @WorkCountry, 
                    @WorkState, @WorkCity, @WorkDescription, @WorkStartDate, @WorkEndDate)
            END
        `);

                        // Log the result of the query
                        console.log('Update/Insert successful:', result);
                    } catch (error) {
                        // Log any error that occurs during the query
                        console.error('Error updating or inserting work record:', error);
                    }


                }
            }
        }

        // Send success response
        res.status(200).send('Work entries processed successfully');
    } catch (error) {
        console.error('Error saving work info:', error);
        res.status(501).send('Failed to save work info');
    }
};

module.exports.deleteCVWork = async (req, res) => {
    const { WorkExpID } = req.body;
    console.log(WorkExpID);
    // Validate input
    if (!WorkExpID) {
        return res.status(200).json({ message: 'No WorkExpID' });
    }

    try {
        const pool = await poolPromise;

        // Check if the work experience entry exists based on job_title and company_name
        const existingWork = await pool.request()
            .input('RefID', sql.Int, WorkExpID)
            .query(`
            DELETE FROM Work
            WHERE RefID = @RefID
        `);

        if (existingWork.rowsAffected[0] > 0) {
            // Return 200 status code for successful deletion
            return res.status(200).json({ message: 'Education entry deleted successfully' });
        } else {
            // Return 201 status code if no matching entry was found
            return res.status(201).json({ message: 'Education entry not found' });
        }
    } catch (error) {
        console.error('Error deleting work experience:', error.message);
        res.status(500).json({ message: 'Error deleting work experience' });
    }
};



//Education ----------

module.exports.saveCVEducation = async (req, res) => {
    const { accountID, educationEntries } = req.body;
    console.log(educationEntries);

    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    try {
        const sainoPool = await poolPromise;


        // Process existing education entries (updates or deletes)

        if (educationEntries && educationEntries.length > 0) {
            for (const entry of educationEntries) {
                const {
                    EduBacID, level, field_of_study, institute_name, institute_country, institute_city, institute_state, start_date, end_date, isPublic
                } = entry;


                if (isPublic === false) {
                    console.log("wRONG");
                    // Call deleteCVEducation function if isPublic is unchecked (false)
                    await module.exports.deleteCVEducation({
                        body: { EduBacID }
                    }, {
                        status: (code) => ({
                            json: (message) => console.log(`Delete status: ${code}, message: ${JSON.stringify(message)}`)
                        })
                    });
                }
                else {
                    console.log("EduBacID: " + EduBacID);
                    console.log("Corredcct");

                    // Use IF EXISTS to check and either update or insert
                    await sainoPool.request()
                        .input('RefID', sql.Int, EduBacID)
                        .input('StudentAccID', sql.Int, accountID) // Assuming accountID is StudentAccID
                        .input('LevelEdu', sql.NVarChar, level)
                        .input('FieldOfStudy', sql.NVarChar, field_of_study)
                        .input('InstituteName', sql.NVarChar, institute_name)
                        .input('InstituteCountry', sql.NVarChar, institute_country)
                        .input('InstituteCity', sql.NVarChar, institute_city)
                        .input('InstituteState', sql.NVarChar, institute_state)
                        .input('EduStartDate', sql.NVarChar, start_date)
                        .input('EduEndDate', sql.NVarChar, end_date)
                        .query(`
                            IF EXISTS (
                                SELECT 1 FROM Education 
                                WHERE RefID = @RefID
                            )
                            BEGIN
                                -- Update the education entry if it exists
                                UPDATE Education
                                SET StudentAccID = @StudentAccID, LevelEdu = @LevelEdu, FieldOfStudy = @FieldOfStudy, 
                                    InstituteName = @InstituteName, InstituteCountry = @InstituteCountry, 
                                    InstituteCity = @InstituteCity, InstituteState = @InstituteState, 
                                    EduStartDate = @EduStartDate, EduEndDate = @EduEndDate
                                WHERE RefID = @RefID
                            END
                            ELSE
                            BEGIN
                                -- Insert the education entry if it doesn't exist
                                INSERT INTO Education (RefID, StudentAccID, LevelEdu, FieldOfStudy, InstituteName, InstituteCountry, 
                                    InstituteCity, InstituteState, EduStartDate, EduEndDate)
                                VALUES (@RefID, @StudentAccID, @LevelEdu, @FieldOfStudy, @InstituteName, @InstituteCountry, 
                                    @InstituteCity, @InstituteState, @EduStartDate, @EduEndDate)
                            END
                        `);
                }
            }
        }

        console.log("save education successful");
        // Sending success response after all operations are complete
        res.status(200).send('Education entries processed successfully');

    } catch (error) {
        console.error('Error saving education info:', error.message);
        res.status(500).send('Failed to save education info');
    }
};

module.exports.deleteCVEducation = async (req, res) => {
    const { EduBacID } = req.body;

    if (!EduBacID) {
        return res.status(400).json({ message: 'EduBacID is required' });
    }

    try {
        const pool = await poolPromise;

        // Directly delete the education entry based on the RefID (EduBacID)
        const deleteResult = await pool.request()
            .input('RefID', sql.Int, EduBacID)
            .query(`
                DELETE FROM Education
                WHERE RefID = @RefID
            `);

        // Check if any rows were affected (i.e., entry was deleted)
        if (deleteResult.rowsAffected[0] > 0) {
            // Return 200 status code for successful deletion
            return res.status(200).json({ message: 'Education entry deleted successfully' });
        } else {
            // Return 201 status code if no matching entry was found
            return res.status(201).json({ message: 'Education entry not found' });
        }
    } catch (error) {
        console.error('Error deleting education entry:', error.message);
        return res.status(500).json({ message: 'Error deleting education entry' });
    }
};



//Certification ----------
module.exports.saveCVCertification = async (req, res) => {
    const { accountID, CerID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate } = req.body;

    // Validate input
    if (!accountID) {
        return res.status(400).send('Account ID is required');
    }
    if (!CerName || !CerIssuer || !CerAcquiredDate) {
        return res.status(400).send('Certification Name, Issuer, and Acquired Date are required');
    }

    try {
        const pool = await poolPromise;

        // Insert new certification into the second database with CerID saved as RefID
        await pool.request()
            .input('StudentAccID', sql.Int, accountID)  // Use accountID as StudentAccID
            .input('RefID', sql.Int, CerID)  // Use CerID from the first function as RefID
            .input('CerName', sql.NVarChar(50), CerName)
            .input('CerEmail', sql.NVarChar(50), CerEmail)
            .input('CerType', sql.NVarChar(50), CerType)
            .input('CerIssuer', sql.NVarChar(50), CerIssuer)
            .input('CerDescription', sql.NVarChar(200), CerDescription)
            .input('CerAcquiredDate', sql.DateTime, CerAcquiredDate)
            .query(`
                INSERT INTO Certification (StudentAccID, RefID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate)
                OUTPUT INSERTED.CerID
                VALUES (@StudentAccID, @RefID, @CerName, @CerEmail, @CerType, @CerIssuer, @CerDescription, @CerAcquiredDate)
            `);

        res.status(200).json({
            message: 'Certification saved successfully in second database',
            CerID,  // Return new CerID if needed
            CerName,
            CerEmail,
            CerType,
            CerIssuer,
            CerDescription,
            CerAcquiredDate
        });

    } catch (error) {
        console.error('Error saving certification in the second database:', error.message);
        res.status(501).send('Server error');
    }
};

module.exports.updateCVCertification = async (req, res) => {
    const { CerID, accountID, certification } = req.body;
    const { Name, Email, CertificationType, Issuer, Description, CertificationAcquireDate } = certification;
    // Validate input
    const CerName = Name;
    const CerEmail = Email;
    const CerType = CertificationType;
    const CerIssuer = Issuer;
    const CerDescription = Description;

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
        await pool.request()
            .input('StudentAccID', sql.Int, accountID)
            .input('CerName', sql.NVarChar(50), CerName)
            .input('RefID', sql.Int, CerID)
            .input('CerEmail', sql.NVarChar(50), CerEmail)
            .input('CerType', sql.NVarChar(50), CerType)
            .input('CerIssuer', sql.NVarChar(50), CerIssuer)
            .input('CerDescription', sql.NVarChar(200), CerDescription)
            .input('CerAcquiredDate', sql.DateTime, CertificationAcquireDate)
            .query(`
                INSERT INTO Certification (StudentAccID, CerName, CerEmail, CerType, CerIssuer, CerDescription, CerAcquiredDate, RefID)
                VALUES (@StudentAccID, @CerName, @CerEmail, @CerType, @CerIssuer, @CerDescription, @CerAcquiredDate, @RefID)
            `);

        console.log("Certification saved successfully");


        // Return the new CerID along with a success message
        res.status(200).json({
            message: 'Certification saved successfully',
        });

        console.log("Certification save operation completed.");
    } catch (error) {
        console.error('Error saving certification:', error.message);
        res.status(500).send('Server error');
    }
};

module.exports.deleteCVCertification = async (req, res) => {
    const { accountID, CerID, isPublic } = req.body;
    console.log("CALL DELETE");
    console.log(CerID);
    console.log(accountID);
    if (!accountID) {
        console.log("Error");
        return res.status(400).json({ message: 'Missing required fields' });
    }

    try {
        const pool = await poolPromise;

        await pool.request()
            .input('StudentAccID', sql.Int, accountID)
            .input('RefID', sql.Int, CerID)
            .input('isPublic', sql.Int, isPublic)
            .query(`
          DELETE FROM Certification
          WHERE StudentAccID = @StudentAccID
          AND RefID = @RefID
        `);
        console.log("Done");

        res.status(200).json({ message: 'Certification deleted successfully' });
    } catch (error) {
        console.error('Error deleting certification:', error);
        res.status(500).json({ message: 'Internal Server Error' });
    }

};



//Qualification ----------

// module.exports.saveCVQuali = async (req, res) => {
//     const { accountID, qualifications } = req.body;

//     if (!accountID) {
//         return res.status(400).send('Account ID is required');
//     }

//     try {
//         const pool = await poolPromise;

//         for (const qual of qualifications) {
//             const { quaTitle, quaIssuer, quaDescription, quaAcquiredDate, isPublic } = qual;

//             // Check if the qualification already exists by description, issuer, and acquired date
//             const existingQualification = await pool.request()
//                 .input('CerDescription', sql.NVarChar, quaDescription)
//                 .input('CerIssuer', sql.NVarChar, quaIssuer)
//                 .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
//                 .query(`
//                     SELECT CerID FROM Qualification
//                     WHERE CerDescription = @CerDescription AND CerIssuer = @CerIssuer AND CerAcquiredDate = @CerAcquiredDate
//                 `);

//             // If the qualification exists
//             if (existingQualification.recordset.length > 0) {

//                 if (isPublic === false) {
//                     // Delete the existing qualification if isPublic is false
//                     await pool.request()
//                         .input('CerDescription', sql.NVarChar, quaDescription)
//                         .input('CerIssuer', sql.NVarChar, quaIssuer)
//                         .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
//                         .query(`
//                             DELETE FROM Qualification
//                             WHERE CerDescription = @CerDescription AND CerIssuer = @CerIssuer AND CerAcquiredDate = @CerAcquiredDate
//                         `);
//                 } else {
//                     // Update the existing qualification if isPublic is true
//                     await pool.request()
//                         .input('CerTitle', sql.NVarChar, quaTitle)
//                         .input('CerIssuer', sql.NVarChar, quaIssuer)
//                         .input('CerDescription', sql.NVarChar, quaDescription)
//                         .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
//                         .query(`
//                             UPDATE Qualification
//                             SET CerTitle = @CerTitle, CerIssuer = @CerIssuer, CerDescription = @CerDescription, CerAcquiredDate = @CerAcquiredDate
//                             WHERE CerDescription = @CerDescription AND CerIssuer = @CerIssuer AND CerAcquiredDate = @CerAcquiredDate
//                         `);
//                 }
//             } else if (isPublic === true) {
//                 // Insert the new qualification if it doesn't exist and isPublic is true
//                 await pool.request()
//                     .input('UserID', sql.Int, accountID)  // Map accountID to UserID
//                     .input('CerTitle', sql.NVarChar, quaTitle)
//                     .input('CerIssuer', sql.NVarChar, quaIssuer)
//                     .input('CerDescription', sql.NVarChar, quaDescription)
//                     .input('CerAcquiredDate', sql.DateTime, quaAcquiredDate)
//                     .query(`
//                         INSERT INTO Qualification (UserID, CerTitle, CerIssuer, CerDescription, CerAcquiredDate)
//                         OUTPUT INSERTED.CerID
//                         VALUES (@UserID, @CerTitle, @CerIssuer, @CerDescription, @CerAcquiredDate)
//                     `);
//             }
//         }

//         // Send success response
//         res.status(200).send('Qualification data processed successfully');
//     } catch (error) {
//         console.error('Error processing qualification data:', error);
//         res.status(500).send('Error occurred while processing qualification data');
//     }
// };

// module.exports.deleteCVQualification = async (req, res) => {
//     const { quaDescription, quaIssuer, quaAcquiredDate } = req.body;

//     if (!quaDescription || !quaIssuer || !quaAcquiredDate) {
//         return res.status(400).json({ message: 'Description, Issuer, and Acquired Date are required' });
//     }

//     try {
//         const pool = await poolPromise;

//         // Check if the qualification entry exists based on description, issuer, and acquired date
//         const existingQualification = await pool.request()
//             .input('QuaDescription', sql.NVarChar, quaDescription)
//             .input('QuaIssuer', sql.NVarChar, quaIssuer)
//             .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
//             .query(`
//                 SELECT COUNT(*) AS count FROM Qualification
//                 WHERE QuaDescription = @QuaDescription AND QuaIssuer = @QuaIssuer AND QuaAcquiredDate = @QuaAcquiredDate
//             `);

//         if (existingQualification.recordset[0].count > 0) {
//             // Delete the qualification entry
//             await pool.request()
//                 .input('QuaDescription', sql.NVarChar, quaDescription)
//                 .input('QuaIssuer', sql.NVarChar, quaIssuer)
//                 .input('QuaAcquiredDate', sql.DateTime, quaAcquiredDate)
//                 .query(`
//                     DELETE FROM Qualification
//                     WHERE QuaDescription = @QuaDescription AND QuaIssuer = @QuaIssuer AND QuaAcquiredDate = @QuaAcquiredDate
//                 `);

//             res.status(200).json({ message: 'Qualification deleted successfully' });
//         } else {
//             res.status(404).json({ message: 'Qualification not found' });
//         }
//     } catch (error) {
//         console.error('Error deleting qualification:', error.message);
//         res.status(500).json({ message: 'Error deleting qualification' });
//     }
// };