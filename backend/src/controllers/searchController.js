const sql = require('mssql');
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

module.exports.search = async (req, res) => {
    try {
        const { searchType, searchQuery } = req.body;

        if (!searchType || !searchQuery) {
            return res.status(400).json({ error: 'searchType and searchQuery are required' });
        }

        const upperSearchTerm = searchQuery.toUpperCase(); // Convert search term to uppercase

        const pool = await poolPromise;
        let query;

        if (searchType.toLowerCase() === 'education') {
            query = `
                    SELECT UserID, EduBacID, InstituteName, LevelEdu, FieldOfStudy, EduStartDate, EduEndDate 
                    FROM Education 
                    WHERE UPPER(InstituteName) LIKE '%' + @searchTerm + '%'
                `;
        } else if (searchType.toLowerCase() === 'skills') {
            query = `
                    SELECT UserID, IntelID, InteHighlight, InteDescription 
                    FROM Skills 
                    WHERE UPPER(InteHighlight) LIKE '%' + @searchTerm + '%'
                `;
        } else {
            return res.status(400).json({ error: 'Invalid searchType. Must be "education" or "skills".' });
        }

        const searchResults = await pool.request()
            .input('searchTerm', sql.VarChar, upperSearchTerm)
            .query(query);

        if (searchResults.recordset.length === 0) {
            return res.status(200).json([]); // No results found
        }

        // Retrieve Profile details based on UserID
        const userIds = searchResults.recordset.map(result => result.UserID);
        const profileQuery = `
                SELECT UserID, Name, Age, Email_Address 
                FROM Profile 
                WHERE UserID IN (${userIds.join(',')})
            `;
        const profileResults = await pool.request().query(profileQuery);

        // Map the profile details to the corresponding results
        const profiles = profileResults.recordset.reduce((acc, profile) => {
            acc[profile.UserID] = profile;
            return acc;
        }, {});

        // Combine the search results with their respective profile information
        // Filter out results where the profile is null or undefined
        const combinedResults = searchResults.recordset
            .map(result => ({
                ...result,
                profile: profiles[result.UserID]
            }))
            .filter(result => result.profile); // Remove entries with no profile

        res.status(200).json(combinedResults);
    } catch (err) {
        console.error('Search Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }
};



module.exports.showDetails = async (req, res) => {
    try {
        const { userID } = req.body; // Get userID from the request body

        if (!userID) {
            return res.status(400).json({ error: 'UserID is required' });
        }

        const pool = await poolPromise;

        // Fetch Profile information
        const profileQuery = `
            SELECT UserID, Name, Age, Email_Address, Mobile_Number, Address, Description
            FROM Profile 
            WHERE UserID = @userID
        `;
        const profileResult = await pool.request()
            .input('userID', sql.Int, userID)
            .query(profileQuery);

        if (profileResult.recordset.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const userDetails = profileResult.recordset[0];

        // Fetch Education information
        const educationQuery = `
            SELECT EduBacID, InstituteName, LevelEdu, FieldOfStudy, 
            CONVERT(VARCHAR(10), EduStartDate, 120) AS EduStartDate, 
            CONVERT(VARCHAR(10), EduEndDate, 120) AS EduEndDate 
            FROM Education 
            WHERE UserID = @userID
        `;
        const educationResult = await pool.request()
            .input('userID', sql.Int, userID)
            .query(educationQuery);

        // Fetch Skills information
        const skillsQuery = `
            SELECT IntelID, InteHighlight, InteDescription 
            FROM Skills 
            WHERE UserID = @userID
        `;
        const skillsResult = await pool.request()
            .input('userID', sql.Int, userID)
            .query(skillsQuery);

        // Fetch Certification information (replacing Qualification with Certification)
        const certificationQuery = `
            SELECT CerID, CerName, CerEmail, CerType, CerIssuer, CerDescription, 
            CONVERT(VARCHAR(10), CerAcquiredDate, 120) AS CerAcquiredDate 
            FROM Certification 
            WHERE userID = @userID
        `;
        const certificationResult = await pool.request()
            .input('userID', sql.Int, userID)
            .query(certificationQuery);

        // Fetch Work Experience information
        const workExperienceQuery = `
            SELECT WorkExpID, WorkTitle, WorkCompany, WorkIndustry, WorkCountry, WorkCity, WorkDescription, 
            CONVERT(VARCHAR(10), WorkStartDate, 120) AS WorkStartDate, 
            CONVERT(VARCHAR(10), WorkEndDate, 120) AS WorkEndDate 
            FROM Work 
            WHERE UserID = @userID
        `;
        const workExperienceResult = await pool.request()
            .input('userID', sql.Int, userID)
            .query(workExperienceQuery);

        // Combine all the details into one object
        const combinedDetails = {
            profile: userDetails,
            education: educationResult.recordset,
            skills: skillsResult.recordset,
            certification: certificationResult.recordset,  // Updated here
            workExperience: workExperienceResult.recordset,
        };

        res.status(200).json(combinedDetails);
    } catch (err) {
        console.error('Show Details Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }
};
