const sql = require('mssql');

let holders = [];
let Credential = null;

const getLatestCredentialID = async () => {
  try {
    const request = new sql.Request();
    const result = await request.query('SELECT TOP 1 id FROM Credentials ORDER BY id DESC');
    return result.recordset[0].id ;
  } catch (err) {
    console.error(err);
    throw new Error('Failed to fetch latest Credential ID from database');
  }
};

const addHolderAndCredential = (req, res) => {

  const { holders: newHolders, credential } = req.body;
  
  if (Array.isArray(newHolders)) {
    holders.push(...newHolders);
  } else if (newHolders && newHolders.name && newHolders.email && newHolders.phoneNo && newHolders.description && newHolders.address) {
    holders.push(newHolders);
  } else {
    return res.status(400).send({ error: 'Invalid holder data' });
  }
  
  if (credential && credential.credentialType && credential.issuancedate) {
    Credential = credential;
    sendCredentialToDatabase(res);
  } else {
    return res.status(400).send({ error: 'Invalid credential data' });
  }
};

const sendCredentialToDatabase = async (res) => {

  if (!Credential) {
    return res.status(400).send({ error: 'No Credential to send' });
  }
  
  try {
    const request = new sql.Request();
    request.input('userid', sql.Int, 1); 
    request.input('credentialType', sql.NVarChar, Credential.credentialType);
    request.input('issuanceDate', sql.Date, Credential.issuancedate);
    
    await request.query('INSERT INTO Credentials (userid, credentialType, issuanceDate) VALUES (@userid, @credentialType, @issuanceDate)');
    
    const credentialID = await getLatestCredentialID();
    console.log("credential id:"+credentialID);
    await sendHoldersToDatabase(res, credentialID);
  } catch (err) {
    console.error(err);
    res.status(500).send({ error: 'Failed to insert credential into database' });
  }
};

const sendHoldersToDatabase = async (res, ID) => {
  if (!holders.length) {
    return res.status(400).send({ error: 'No holders to send' });
  }

  try {
    const transaction = new sql.Transaction();
    await transaction.begin();

    for (const holder of holders) {
      const request = new sql.Request(transaction); // Create a new request for each holder
      request.input('ID', sql.Int, ID);
      request.input('name', sql.NVarChar, holder.name);
      request.input('email', sql.NVarChar, holder.email);
      request.input('phoneNo', sql.NVarChar, holder.phoneNo);
      request.input('description', sql.NVarChar, holder.description);
      request.input('address', sql.NVarChar, holder.address);
      request.input('status', sql.NVarChar, 'Pending');

      await request.query(`
        INSERT INTO Holders (CredentialRefID, name, email, phoneNo, description, address, status)
        VALUES (@ID, @name, @email, @phoneNo, @description, @address, @status)
      `);
    }

    await transaction.commit();

    holders = [];
    Credential = null;
    res.status(201).send({ message: 'Holders and credential processed successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).send({ error: 'Failed to insert holders into database' });
  }
};

module.exports = {
  addHolderAndCredential,
};
