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

        // Check if searchType and searchQuery are provided
        if (!searchType || !searchQuery) {
            return res.status(400).json({ error: 'searchType and searchQuery are required' });
        }

        const upperSearchTerm = searchQuery.toUpperCase(); // Convert search term to uppercase

        const pool = await poolPromise;
        let query;

        if (searchType.toLowerCase() === 'education') {
            query = `
                SELECT * FROM Education 
                WHERE UPPER(InstituteName) LIKE '%' + @searchTerm + '%'
            `;
        } else if (searchType.toLowerCase() === 'skills') {
            query = `
                SELECT * FROM Skills 
                WHERE UPPER(InteHighlight) LIKE '%' + @searchTerm + '%'
            `;
        } else {
            return res.status(400).json({ error: 'Invalid searchType. Must be "education" or "skills".' });
        }

        const result = await pool.request()
            .input('searchTerm', sql.VarChar, upperSearchTerm)
            .query(query);

        if (result.recordset.length > 0) {
            res.status(200).json(result.recordset);
        } else {
            res.status(200).json([]); // No results found
        }
    } catch (err) {
        console.error('Search Error:', err);
        res.status(500).json({ error: 'Server error. Please try again later.' });
    }

};
