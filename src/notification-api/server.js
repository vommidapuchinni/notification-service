const express = require('express');
const app = express();
const port = process.env.PORT || 80;

app.get('/', (req, res) => {
  res.send('Hello from Notification API!');
});

app.listen(port, () => {
  console.log(`Notification API running on port ${port}`);
});

