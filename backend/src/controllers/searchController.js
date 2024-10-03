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
        console.log(req.body);
        const { searchType, searchQuery, sortOption, page = 1, limit = 10 } = req.body;
        console.log(searchType);
        console.log(searchQuery);
        console.log(sortOption);
        console.log(page);
        console.log(limit);

        if (!searchType || !searchQuery) {
            return res.status(400).json({ error: 'searchType and searchQuery are required' });
        }

        const upperSearchTerm = searchQuery.toUpperCase();
        const offset = (page - 1) * limit; // Pagination offset

        const pool = await poolPromise;
        let query, orderBy;

        if (searchType.toLowerCase() === 'education') {
            orderBy = sortOption === 'Graduated Date (Far to Near)' ? 'EduEndDate ASC' : 'EduEndDate DESC';
            query = `
                    SELECT StudentAccID, EduBacID, InstituteName, LevelEdu, FieldOfStudy, EduStartDate, EduEndDate 
                    FROM Education 
                    WHERE CONTAINS(InstituteName, @searchTerm)
                    ORDER BY ${orderBy}
                    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY;
                `;
        } else if (searchType.toLowerCase() === 'skills') {
            orderBy = sortOption === 'Level (Master to Beginner)' ? 'SoftLevel DESC' : 'SoftLevel ASC';
            query = `
                    SELECT StudentAccID, SoftID, SoftHighlight, SoftDescription, SoftLevel 
                    FROM SoftSkill 
                    WHERE CONTAINS(SoftHighlight, @searchTerm)
                    ORDER BY ${orderBy}
                    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY;
                `;
        } else {
            return res.status(400).json({ error: 'Invalid searchType. Must be "education" or "skills".' });
        }

        const searchResults = await pool.request()
            .input('searchTerm', sql.NVarChar, `"*${upperSearchTerm}*"`)
            .input('offset', sql.Int, offset)
            .input('limit', sql.Int, limit)
            .query(query);

        if (searchResults.recordset.length === 0) {
            return res.status(200).json({ results: [], totalPages: 1 });
        }

        const studentAccIds = searchResults.recordset.map(result => result.StudentAccID);
        const profileQuery = `
                    SELECT StudentAccID, Name, Age, Email_Address 
                    FROM Profile 
                    WHERE StudentAccID IN (${studentAccIds.join(',')})
                `;
        const profileResults = await pool.request().query(profileQuery);

        const profiles = profileResults.recordset.reduce((acc, profile) => {
            acc[profile.StudentAccID] = profile;
            return acc;
        }, {});

        const combinedResults = searchResults.recordset.map(result => ({
            ...result,
            profile: profiles[result.StudentAccID]
        }));

        // Get total count of results for pagination
        const countQuery = searchType.toLowerCase() === 'education' ?
            `SELECT COUNT(*) AS total FROM Education WHERE CONTAINS(InstituteName, @searchTerm)` :
            `SELECT COUNT(*) AS total FROM SoftSkill WHERE CONTAINS(SoftHighlight, @searchTerm)`;
        const totalCountResult = await pool.request()
            .input('searchTerm', sql.NVarChar, `"*${upperSearchTerm}*"`)
            .query(countQuery);
        const totalResults = totalCountResult.recordset[0].total;
        const totalPages = Math.ceil(totalResults / limit);

        res.status(200).json({ results: combinedResults, totalPages });
    } catch (err) {
        console.error('Search Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }
};

module.exports.showDetails = async (req, res) => {
    try {
        const { StudentAccID } = req.body; // Get StudentAccID from the request body

        if (!StudentAccID) {
            return res.status(400).json({ error: 'StudentAccID is required' });
        }

        const pool = await poolPromise;

        // Fetch Profile information
        const profileQuery = `
            SELECT StudentAccID, Name, Age, Email_Address, Mobile_Number, Address, Description
            FROM Profile 
            WHERE StudentAccID = @StudentAccID
        `;
        const profileResult = await pool.request()
            .input('StudentAccID', sql.Int, StudentAccID)
            .query(profileQuery);

        if (profileResult.recordset.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const userDetails = profileResult.recordset[0];

        // Fetch Education information
        const educationQuery = `
            SELECT EduBacID, InstituteName, LevelEdu, FieldOfStudy, InstituteCountry, InstituteState, InstituteCity, 
            CONVERT(VARCHAR(10), EduStartDate, 120) AS EduStartDate, 
            CONVERT(VARCHAR(10), EduEndDate, 120) AS EduEndDate 
            FROM Education 
            WHERE StudentAccID = @StudentAccID
        `;
        const educationResult = await pool.request()
            .input('StudentAccID', sql.Int, StudentAccID)
            .query(educationQuery);

        // Fetch SoftSkill information
        const skillsQuery = `
            SELECT SoftID, SoftHighlight, SoftDescription, SoftLevel 
            FROM SoftSkill 
            WHERE StudentAccID = @StudentAccID
        `;
        const skillsResult = await pool.request()
            .input('StudentAccID', sql.Int, StudentAccID)
            .query(skillsQuery);

        // Fetch Certification information
        const certificationQuery = `
            SELECT CerID, CerName, CerEmail, CerType, CerIssuer, CerDescription, 
            CONVERT(VARCHAR(10), CerAcquiredDate, 120) AS CerAcquiredDate 
            FROM Certification 
            WHERE StudentAccID = @StudentAccID
        `;
        const certificationResult = await pool.request()
            .input('StudentAccID', sql.Int, StudentAccID)
            .query(certificationQuery);

        // Fetch Work Experience information
        const workExperienceQuery = `
            SELECT WorkExpID, WorkTitle, WorkCompany, WorkIndustry, WorkCountry, WorkCity, WorkDescription, 
            CONVERT(VARCHAR(10), WorkStartDate, 120) AS WorkStartDate, 
            CONVERT(VARCHAR(10), WorkEndDate, 120) AS WorkEndDate 
            FROM Work 
            WHERE StudentAccID = @StudentAccID
        `;
        const workExperienceResult = await pool.request()
            .input('StudentAccID', sql.Int, StudentAccID)
            .query(workExperienceQuery);

        // Combine all the details into one object
        const combinedDetails = {
            profile: userDetails,
            education: educationResult.recordset,
            skills: skillsResult.recordset,
            certification: certificationResult.recordset,
            workExperience: workExperienceResult.recordset,
        };

        res.status(200).json(combinedDetails);
    } catch (err) {
        console.error('Show Details Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }
};

