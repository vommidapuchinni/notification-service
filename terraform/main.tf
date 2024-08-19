provider "aws" {
  region = "us-east-1"
}

# VPC Definition
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "subnet_association" {
  count = length(aws_subnet.main)
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main.id
}

# Subnet Definitions
resource "aws_subnet" "main" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "main-subnet-${count.index}"
  }
}

# Data source for Availability Zones
data "aws_availability_zones" "available" {}

# Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer
resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for s in aws_subnet.main : s.id]

  enable_deletion_protection = false

  access_logs {
    bucket  = "my-log-bucket"
    enabled = true
  }

  enable_cross_zone_load_balancing = true
}

# Target Group for Notification API
resource "aws_lb_target_group" "notification_api" {
  name     = "notification-api-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}

# Target Group for Email Sender
resource "aws_lb_target_group" "email_sender" {
  name     = "email-sender-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}

# Load Balancer Listener for Notification API
resource "aws_lb_listener" "notification_api" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notification_api.arn
  }
}

# Load Balancer Listener for Email Sender
resource "aws_lb_listener" "email_sender" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.email_sender.arn
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role      = aws_iam_role.ecs_task_execution_role.name
}

# ECR Repository for Notification API
resource "aws_ecr_repository" "notification_api_repo" {
  name = "notification-api-repo"
}

# ECR Repository for Email Sender
resource "aws_ecr_repository" "email_sender_repo" {
  name = "email-sender-repo"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}

# ECS Task Definition for Notification API
resource "aws_ecs_task_definition" "notification_task" {
  family                = "notification-task"
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"

  container_definitions = jsonencode([{
    name      = "notification-api"
    image     = "${aws_ecr_repository.notification_api_repo.repository_url}:latest"
    essential = true
    portMappings = [
      {
        containerPort = 8080
        hostPort      = 8080
        protocol      = "tcp"
      }
    ]
  }])
}

# ECS Task Definition for Email Sender
resource "aws_ecs_task_definition" "email_task" {
  family                = "email-task"
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"

  container_definitions = jsonencode([{
    name      = "email-sender"
    image     = "${aws_ecr_repository.email_sender_repo.repository_url}:latest"
    essential = true
    portMappings = [
      {
        containerPort = 8081
        hostPort      = 8081
        protocol      = "tcp"
      }
    ]
  }])
}

# ECS Service for Notification API
resource "aws_ecs_service" "notification_service" {
  name            = "notification-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.notification_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [for s in aws_subnet.main : s.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.lb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.notification_api.arn
    container_name   = "notification-api"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.notification_api]
}

# ECS Service for Email Sender
resource "aws_ecs_service" "email_service" {
  name            = "email-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.email_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [for s in aws_subnet.main : s.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.lb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.email_sender.arn
    container_name   = "email-sender"
    container_port   = 8081
  }

  depends_on = [aws_lb_listener.email_sender]
}

# Outputs
output "notification_api_repo_url" {
  value = aws_ecr_repository.notification_api_repo.repository_url
}

output "email_sender_repo_url" {
  value = aws_ecr_repository.email_sender_repo.repository_url
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

