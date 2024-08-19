variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  default     = "10.0.1.0/24"
}

variable "notification_api_image" {
  description = "Docker image URI for the Notification API"
  type        = string
}

variable "email_sender_image" {
  description = "Docker image URI for the Email Sender"
  type        = string
}

