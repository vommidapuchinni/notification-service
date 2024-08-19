const express = require('express');
const app = express();
const port = process.env.PORT || 80;

app.get('/', (req, res) => {
  res.send('Hello from Email Sender!');
});

app.listen(port, () => {
  console.log(`Email Sender running on port ${port}`);
});

