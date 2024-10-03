const app = require('./app');
const port = process.env.PORT || 3010;

app.listen(port, () => {
    console.log(`Server is running on http://172.16.20.25:${port}`);
});
