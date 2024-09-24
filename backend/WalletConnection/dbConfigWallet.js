const dbConfig = {
    user: 'XH',
    password: 'System@123',
    server: '127.0.0.3',
    database: 'Wallet',
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
