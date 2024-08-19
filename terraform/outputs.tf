output "notification_api_url" {
  description = "URL of the Notification API service"
  value       = aws_lb.main.dns_name
}

output "email_sender_url" {
  description = "URL of the Email Sender service"
  value       = aws_lb.main.dns_name
}

