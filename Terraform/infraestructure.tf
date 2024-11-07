# main.tf

provider "aws" {
  region = "us-east-1"  # Change this to your preferred region
}

# Create SSH key pair from local public key
resource "aws_key_pair" "workshop_key" {
  key_name   = "workshop_ot_key"
  public_key = file("~/.ssh/id_rsa.pub")  # Ensure this public key exists
}

# Security Group for EC2 instance
resource "aws_security_group" "workshop_sg" {
  name        = "workshop_ot_sg"
  description = "Security Group for OT Workshop EC2 instance"

  # Allow SSH only from specific IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["98.97.134.240/32", "98.97.134.148/32"]
  }

  # Allow traffic on port 502 for PLC (Modbus) simulation
  ingress {
    from_port   = 502
    to_port     = 502
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Change to a specific range if possible
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creation of EC2 instance for SCADA
resource "aws_instance" "workshop_ec2_scada" {
  ami           = "ami-06b21ccaeff8cd686"  # Specified AMI
  instance_type = "t2.micro"               # Specified instance type

  # Assign Security Group
  vpc_security_group_ids = [aws_security_group.workshop_sg.id]

  # Enable public IP for access
  associate_public_ip_address = true

  # Use the SSH key pair created by Terraform
  key_name = aws_key_pair.workshop_key.key_name

  # Tags for resource identification
  tags = {
    Name = "workshop-ot-scada-instance"
  }

  # User Data for automatic installation of dependencies
  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install git
yum install -y python3 git python3-pip
EOF
}


# IAM Role (optional for additional permissions)
resource "aws_iam_role" "ec2_role" {
  name = "workshop_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the IAM Role to the EC2 instance (optional)
resource "aws_iam_instance_profile" "workshop_instance_profile" {
  name = "workshop_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Creation of EC2 instance for PLC
resource "aws_instance" "workshop_ec2_plc" {
  ami                         = "ami-06b21ccaeff8cd686"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.workshop_sg.id]
  key_name                    = aws_key_pair.workshop_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.workshop_instance_profile.name

  tags = {
    Name = "workshop-ot-plc-instance"
  }

  # User Data for automatic installation of dependencies
  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install git
yum install -y python3 git python3-pip
pip install pymodbus==2.5.3
EOF
}

# Outputs to show the IPs of the EC2 instances
output "workshop_ec2_scada_public_ip" {
  value       = aws_instance.workshop_ec2_scada.public_ip
  description = "Public IP of the SCADA EC2 instance"
}

output "workshop_ec2_plc_public_ip" {
  value       = aws_instance.workshop_ec2_plc.public_ip
  description = "Public IP of the PLC EC2 instance"
}