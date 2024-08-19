const AWS = require('aws-sdk');

const sqs = new AWS.SQS({ region: 'us-east-1' });
const ses = new AWS.SES({ region: 'us-east-1' });

const processMessage = async (message) => {
  const params = {
    Destination: {
      ToAddresses: [message.to],
    },
    Message: {
      Body: {
        Text: { Data: message.body },
      },
      Subject: { Data: message.subject },
    },
    Source: 'sender@example.com', // Replace with a verified email
  };

  await ses.sendEmail(params).promise();
};

const receiveMessages = async () => {
  const params = {
    QueueUrl: process.env.SQS_QUEUE_URL,
    MaxNumberOfMessages: 10,
    VisibilityTimeout: 20,
  };

  const result = await sqs.receiveMessage(params).promise();
  if (result.Messages) {
    for (const msg of result.Messages) {
      await processMessage(JSON.parse(msg.Body));
      await sqs.deleteMessage({ QueueUrl: process.env.SQS_QUEUE_URL, ReceiptHandle: msg.ReceiptHandle }).promise();
    }
  }
};

setInterval(receiveMessages, 5000);

console.log('Email Sender running...');
