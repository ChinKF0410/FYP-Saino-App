/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

const dbConfig = {
    user: 'Saino',
    password: 'Saino',
    server: '127.0.0.1',
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

// const dbConfig = {
//     user: 'sa',
//     password: 'System@123',
//     server: '10.123.10.106',
//     database: 'SAINO',
//     options: {
//         encrypt: true,
//         trustServerCertificate: true,
//         enableArithAbort: true,
//         connectTimeout: 50000,
//         requestTimeout: 50000,
//     },  
//     port: 1433,
// };

module.exports = dbConfig;
