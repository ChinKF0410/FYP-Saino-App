
const dbConfig = {
    user: 'sa',
    password: 'System@123',
    server: '10.123.10.106',
    database: 'SAINO',
    options: {
        encrypt: true,
        trustServerCertificate: true,
        enableArithAbort: true,
        connectTimeout: 50000,
        requestTimeout: 50000,
    },  
    port: 1433,
};

module.exports = dbConfig;
