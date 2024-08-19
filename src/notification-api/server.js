const express = require('express');
const AWS = require('aws-sdk');

const app = express();
app.use(express.json());

const sqs = new AWS.SQS({ region: 'us-east-1' });

app.post('/notify', async (req, res) => {
  const { message } = req.body;

  const params = {
    MessageBody: JSON.stringify(message),
    QueueUrl: process.env.SQS_QUEUE_URL
  };

  try {
    await sqs.sendMessage(params).promise();
    res.status(200).send('Message sent to SQS');
  } catch (err) {
    res.status(500).send('Failed to send message');
  }
});

app.listen(8080, () => {
  console.log('Notification API listening on port 8080');
});
