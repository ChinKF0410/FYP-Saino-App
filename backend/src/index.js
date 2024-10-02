const app = require('./app');
const port = process.env.PORT || 3010;

app.listen(port, () => {
    console.log(`Server is running on http://10.123.10.108:${port}`);
});
