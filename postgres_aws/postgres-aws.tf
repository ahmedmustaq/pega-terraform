provider "aws" {
  region = var.region
}

# Create a security group for the PostgreSQL instance
resource "aws_security_group" "allow_postgres" {
  name        = "allow-postgres"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to specific range, adjust as per requirement
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-postgres"
  }
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-internet-gateway"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the subnet with the route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# Create EC2 Instance to run PostgreSQL PL/Java
resource "aws_instance" "docker_postgres_pljava" {
  ami                         = "ami-0f83016656f175553"  # Replace with appropriate AMI (Ubuntu 20.04)
  instance_type               = var.instance_type
  key_name                    = var.key_name  # Make sure to have an EC2 key pair
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.allow_postgres.name]
  associate_public_ip_address = true

  # Block device mapping for instance storage
  root_block_device {
    volume_size = 30
  }

  # User data for startup script to install Docker and run PostgreSQL-PL/Java container
  user_data = <<-EOF
      #!/bin/bash
      # Update package list and install Docker
      sudo apt-get update
      sudo apt-get install -y docker.io

      # Enable and start Docker service
      sudo systemctl enable docker
      sudo systemctl start docker

      # Run PostgreSQL-PL/Java container using the pega/postgres-pljava-openjdk:11 image
      sudo docker run -d \
        --name postgres-pljava \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=america@786 \
        -e POSTGRES_DB=postgres \
        -p 5432:5432 \
        -v /var/lib/postgresql-persist/data:/var/lib/postgresql/data \
        pegasystems/postgres-pljava-openjdk:11

      # Install AWS CLI
      sudo apt-get install -y awscli

      # Download Pega dump file from S3 bucket
      aws s3 cp s3://terraform-pega/pega.dump /tmp/pega.dump

      # Wait for the container to be fully ready
      sleep 10

      # Copy pega.dump into the container's filesystem
      sudo docker cp /tmp/pega.dump postgres-pljava:/var/lib/postgresql/data/pega.dump

      # Restore the dump into PostgreSQL
      sudo docker exec -i postgres-pljava pg_restore -U postgres -d postgres /var/lib/postgresql/data/pega.dump

      # Expose PostgreSQL port
      sudo ufw allow 5432
  EOF

  tags = {
    Name = "docker-postgres-pljava-instance"
  }
}

# Optional: Output EC2 Instance Public IP
output "instance_public_ip" {
  description = "The public IP of the PostgreSQL EC2 instance"
  value       = aws_instance.docker_postgres_pljava.public_ip
}

# Optional: Output PostgreSQL URL
output "postgres_url" {
  description = "PostgreSQL connection URL"
  value       = "postgres://postgres:america@786@${aws_instance.docker_postgres_pljava.public_ip}:5432/postgres"
}

variable "region" {
  description = "The AWS region to deploy resources in"
  default     = "eu-west-2"
}

variable "availability_zone" {
  description = "The availability zone to deploy the instance in"
  default     = "eu-west-2a"
}

variable "instance_type" {
  description = "The instance type to use for the EC2 instance"
  default     = "t2.medium"
}

variable "key_name" {
  description = "The name of the EC2 Key Pair for SSH access"
  default     = "my-key-pair"
}
