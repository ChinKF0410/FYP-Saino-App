const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const userRoutes = require('./routes/userRoutes');

const app = express();

app.use(cors());
app.use(bodyParser.json({ limit: '10mb' })); // Adjust the limit based on your needs
app.use(bodyParser.urlencoded({ limit: '10mb', extended: true })); // For URL-encoded form data
app.use('/api', userRoutes);

// Root route for testing
app.get('/', (req, res) => {
    res.send('Welcome to the API');
});

module.exports = app;
