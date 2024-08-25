const sql = require('mssql');
const axios = require('axios');

const ACA_PY_URL_ISSUER = 'http://localhost:6011'; // Replace with your issuer agent's URL

let holders = [];
let Credential = null;
let connectionId = null;


async function sendDataToHolder(dataToSend) {

  try {
    // Send a POST request to the receiver server
    const response = await axios.post('http://localhost:3000/receiveData', dataToSend);

    // Log the response from the receiver
    console.log('Response from receiver:', response.data);
  } catch (error) {
    console.error('Error sending data:', error.message);
  }
}
async function sendDataToHolder2(dataToSend) {

  try {
    // Send a POST request to the receiver server
    const response = await axios.post('http://localhost:3000/receiveproposal', dataToSend);

    // Log the response from the receiver
    console.log('Response from receiver:', response.data);
  } catch (error) {
    console.error('Error sending data:', error.message);
  }
}

async function checkLedgerStatus() {
  while (true) {
    try {
      const response = await axios.get(`${ACA_PY_URL}/issue-credential-2.0/records`, {
        headers: {
          'Content-Type': 'application/json',
        }
      });

      const connection = response.data;

      if (connection.state === 'proposal-received') {
        console.log("Proposal is received.");
        return connection.cred_ex_id;
      } else {
        console.log("Waiting for proposal received...");
        await new Promise(resolve => setTimeout(resolve, 5000)); // Wait for 5 seconds
      }
    } catch (error) {
      // Handle error appropriately
      console.error('Error checking ledger status:', error.response ? error.response.data : error.message);
      break;
    }
  }
}


// Main function to handle the process
async function processHoldersAndCredential(newHolders, credential, res) {
  try {

    validateInputs(newHolders, credential);

    holders = Array.isArray(newHolders) ? newHolders : [newHolders];
    Credential = credential;

    const walletdid = await getDID();
    console.log(walletdid);

    await sendCredentialToDatabase();
    const credentialID = await getLatestCredentialID();

    await sendHoldersToDatabase(credentialID);

    const invitation = await createConnectionInvitation();

    await sendDataToHolder(invitation);

    const schema_id = await credentialSchema();
    const defID = await credentialDefinition(schema_id);

    const proposal_data = {
      "credential_preview": {
        "@type": "issue-credential/2.0/credential-preview",
        "attributes": [
          {
            "name": "name",
            "value": holders[0].name
          },
          {
            "name": "email",
            "value": holders[0].email
          },
          {
            "name": "phone",
            "value": holders[0].phone
          },
          {
            "name": "description",
            "value": holders[0].description
          }
        ]
      },
      "filter": {
        "dif": {
          "some_dif_criterion": "string"
        },
        "indy": {
          "cred_def_id": defID,
          "issuer_did": walletdid,
          "schema_id": schema_id,
          "schema_issuer_did": walletdid,
          "schema_name": Credential.credentialType,
          "schema_version": "0.1"
        }
      }
    }

    await sendDataToHolder2(proposal_data);

    // await checkConnectionStatus(token);
    const cred_ex_id = await checkLedgerStatus();
    await sendoffer(cred_ex_id);

    await issueCredential(cred_ex_id);


    res.status(201).send({ message: 'Holders and credential processed successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).send({ error: error.message });
  }
}

// Validate the inputs
function validateInputs(newHolders, credential) {
  if (!Array.isArray(newHolders) && (!newHolders || !isValidHolder(newHolders))) {
    throw new Error('Invalid holder data');
  }

  if (!credential || !credential.credentialType || !credential.issuancedate) {
    throw new Error('Invalid credential data');
  }
}

// Check if the holder data is valid
function isValidHolder(holder) {
  return holder.name && holder.email && holder.phoneNo && holder.description && holder.did;
}

// Get the latest credential ID from the database
async function getLatestCredentialID() {
  try {
    const request = new sql.Request();
    const result = await request.query('SELECT TOP 1 id FROM Credentials ORDER BY id DESC');
    return result.recordset[0].id;
  } catch (err) {
    console.error(err);
    throw new Error('Failed to fetch latest Credential ID from database');
  }
}



// Send the credential to the database
async function sendCredentialToDatabase() {
  try {
    const request = new sql.Request();
    request.input('userid', sql.Int, 1);
    request.input('credentialType', sql.NVarChar, Credential.credentialType);
    request.input('issuanceDate', sql.Date, Credential.issuancedate);

    await request.query('INSERT INTO Credentials (userid, credentialType, issuanceDate) VALUES (@userid, @credentialType, @issuanceDate)');
  } catch (err) {
    console.error(err);
    throw new Error('Failed to insert credential into database');
  }
}

// Send the holders to the database
async function sendHoldersToDatabase(ID) {
  if (!holders.length) {
    throw new Error('No holders to send');
  }

  try {
    const transaction = new sql.Transaction();
    await transaction.begin();

    for (const holder of holders) {
      const request = new sql.Request(transaction);
      request.input('ID', sql.Int, ID);
      request.input('name', sql.NVarChar, holder.name);
      request.input('email', sql.NVarChar, holder.email);
      request.input('phoneNo', sql.NVarChar, holder.phoneNo);
      request.input('description', sql.NVarChar, holder.description);
      request.input('did', sql.NVarChar, holder.did);
      request.input('status', sql.NVarChar, 'Pending');

      await request.query(`
                INSERT INTO Holders (CredentialRefID, name, email, phoneNo, description, address, status)
                VALUES (@ID, @name, @email, @phoneNo, @description, @did, @status)
            `);
    }

    await transaction.commit();
  } catch (err) {
    console.error(err);
    throw new Error('Failed to insert holders into database');
  }
}

// Utility function to create a connection invitation
async function createConnectionInvitation() {
  try {
    const response = await axios.post(`${ACA_PY_URL_ISSUER}/connections/create-invitation`, {}
      , {
        headers: {
          'Content-Type': 'application/json',
        }
      });
    connectionId = response.data.connection_id;
    console.log(response.data.invitation);
    return response.data.invitation;
  } catch (error) {
    console.error('Error creating connection invitation:', error.response ? error.response.data : error.message);
    throw error;
  }
}

async function credentialSchema() {
  try {
    const response = await axios.post(`${ACA_PY_URL_ISSUER}/schemas`, {
      "attributes": [
        "name",
        "email",
        "phone",
        "description"
      ],
      "schema_name": Credential.credentialType,
      "schema_version": "0.1"
    }
      , {
        headers: {
          'Content-Type': 'application/json',
        }
      });
    console.log(response.data);
    return response.data.schema_id;
  } catch (error) {
    console.error('Error creating connection invitation:', error.response ? error.response.data : error.message);
    throw error;
  }
}
async function getDID() {
  try {
    const response = await axios.get(`${ACA_PY_URL_ISSUER}/wallet/did`, {
    }
      , {
        headers: {
          'Content-Type': 'application/json',
        }
      });
    console.log(response.data);
    return response.data.results[0].did;;
  } catch (error) {
    console.error('Error creating connection invitation:', error.response ? error.response.data : error.message);
    throw error;
  }
}
async function credentialDefinition(schema_id) {
  try {
    const response = await axios.post(`${ACA_PY_URL_ISSUER}/credential-definitions`, {
      "schema_id": schema_id,
      "support_revocation": false,
      "tag": Credential.credentialType
    }, {
      headers: {
        'Content-Type': 'application/json',
      }
    });
    console.log('API Response:', response.data); // Log full response data
    if (response.data && response.data.credential_definition && response.data.credential_definition.id) {
      return response.data.credential_definition.id;
    } else {
      throw new Error('Credential definition ID not found in response');
    }
  } catch (error) {
    console.error('Error creating credential definition:', error.response ? error.response.data : error.message);
    throw error;
  }
}


async function sendoffer(cred_ex_id) {
  try {
    const response = await axios.post(`${ACA_PY_URL_ISSUER}/issue-credential/records/${cred_ex_id}/send-offer`, {}
      , {
        headers: {
          'Content-Type': 'application/json',
        }
      });
    console.log(response.data);
    return response.data;
  } catch (error) {
    console.error('Error creating connection invitation:', error.response ? error.response.data : error.message);
    throw error;
  }
}



async function issueCredential(cred_ex_id) {
  try {
    const response = await axios.post(`${ACA_PY_URL_ISSUER}/issue-credential/records/${cred_ex_id}/issue`, { "comment": "This is the credential" }
      , {
        headers: {
          'Content-Type': 'application/json',
        }
      });
    console.log(response.data);
    return response.data;
  } catch (error) {
    console.error('Error creating connection invitation:', error.response ? error.response.data : error.message);
    throw error;
  }
}

// Express route handler to add holders and credential
const addHolderAndCredential = (req, res) => {
  const { holders: newHolders, credential } = req.body;
  processHoldersAndCredential(newHolders, credential, res);
};

module.exports = {
  addHolderAndCredential,
};
