1. Build Docker Images

Navigate to the `docker` directory and build the Docker images:

```bash
cd docker
docker build -t <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/notification-api:latest -f Dockerfile.notification-api .
docker build -t <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/email-sender:latest -f Dockerfile.email-sender .

2. Push Docker Images to ECR

Log in to Amazon ECR and push the Docker images:

bash

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/notification-api:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/email-sender:latest

3. Provision Infrastructure with Terraform

Navigate to the terraform directory and initialize Terraform:

bash

cd terraform
terraform init
terraform apply

4. Access Services

After deployment, you can access the services via the Load Balancer DNS name provided in the Terraform outputs.
Notes

    Make sure to replace placeholders like <your-account-id> with your actual AWS account ID.
    Adjust Terraform variables and configurations according to your requirements.

Architecture Diagram:

+--------------------------+                     +--------------------------+
|                          |                     |                          |
|     AWS Cloud            |                     |     AWS Cloud            |
|     +----------------+   |                     |     +----------------+   |
|     |                |   |                     |     |                |   |
|     |   VPC          |   |                     |     |   VPC          |   |
|     |   +----------+ |   |                     |     |   +----------+ |   |
|     |   |          | |   |                     |     |   |          | |   |
|     |   |  Public  | |   |                     |     |   |  Public  | |   |
|     |   |  Subnet  | |   |                     |     |   |  Subnet  | |   |
|     |   +----------+ |   |                     |     |   +----------+ |   |
|     |                |   |                     |     |                |   |
|     +----------------+   |                     |     +----------------+   |
|            |             |                     |            |             |
|            |             |                     |            |             |
|            |             |                     |            |             |
|            v             |                     |            v             |
|   +------------------+    |                     |    +------------------+   |
|   |   AWS ALB        |    |                     |    |   AWS ALB        |   |
|   |   (Load Balancer)|    |                     |    |   (Load Balancer)|   |
|   +------------------+    |                     |    +------------------+   |
|            |             |                     |            |             |
|            |             |                     |            |             |
|            |             |                     |            |             |
|            v             |                     |            v             |
|   +------------------+    |                     |    +------------------+   |
|   |   ECS Cluster    |    |                     |    |   ECS Cluster    |   |
|   |   (Notification  |    |                     |    |   (Email Sender  |   |
|   |   API Service)   |    |                     |    |   Service)       |   |
|   +------------------+    |                     |    +------------------+   |
|            |             |                     |            |             |
|            |             |                     |            |             |
|            |             |                     |            |             |
|            v             |                     |            v             |
|   +------------------+    |                     |    +------------------+   |
|   |   Docker         |    |                     |    |   Docker         |   |
|   |   Container      |    |                     |    |   Container      |   |
|   |   (Notification  |    |                     |    |   (Email Sender  |   |
|   |   API)           |    |                     |    |   Service)       |   |
|   +------------------+    |                     |    +------------------+   |
|            |             |                     |            |             |
|            v             |                     |            v             |
|   +------------------+    |                     |    +------------------+   |
|   |   Amazon SQS     |    |                     |    |   Amazon SQS     |   |
|   |   (Message Queue)|    |                     |    |   (Message Queue)|   |
|   +------------------+    |                     |    +------------------+   |
|            |             |                     |            |             |
|            v             |                     |            v             |
|   +------------------+    |                     |    +------------------+   |
|   |   AWS App Mesh   |    |                     |    |   AWS App Mesh   |   |
|   |   (Service Mesh) |    |                     |    |   (Service Mesh) |   |
|   +------------------+    |                     |    +------------------+   |
|            |             |                     |            |             |
|            v             |                     |            v             |
|   +------------------+    |                     |    +------------------+   |
|   |   AWS Cloud Map  |    |                     |    |   AWS Cloud Map  |   |
|   |   (Service       |    |                     |    |   (Service       |   |
|   |   Discovery)     |    |                     |    |   Discovery)     |   |
|   +------------------+    |                     |    +------------------+   |
|                          |                     |                          |
+--------------------------+                     +--------------------------+
