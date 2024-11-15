# main.tf

#------------------------------ REGION AWS ------------------------------#
provider "aws" {
  region = "us-east-1"  # Change this to your preferred region
}

#------------------------------ SSH ------------------------------#

# Create SSH key pair from local public key
resource "aws_key_pair" "workshop_key" {
  key_name   = "workshop_ot_key"
  public_key = file("~/.ssh/id_rsa.pub")  # Ensure this public key exists
  # Windows Users
  #public_key = file("C:/Users/YourUsername/.ssh/id_rsa.pub")  # Replace 'YourUsername' with your actual username

}

#------------------------------ IPs ------------------------------#

#IPs from users
variable "allowed_ips" {
  description = "List of IPs allowed to access specific ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]  
  # Load the public IP address from which you will work before exposing it publicly.
  # Example
  # default = ["200.10.120.2/32","3.80.192.75/32"]  
  
}

variable "allowed_all" {
  description = "List of IPs allowed to access specific ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]  
}

#------------------------------ SECURITY GROUPS ------------------------------#

# Security Group for SCADA
resource "aws_security_group" "scada_sg" {
  name        = "workshop_ot_scada_sg"
  description = "Security Group for SCADA instance"

  # Allow SSH from specific IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Allow HTTPS from specific IPs
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # # Outbound rules (optional, default allows all egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for PLC
resource "aws_security_group" "plc_sg" {
  name        = "workshop_ot_plc_sg"
  description = "Security Group for PLC instance"

  # Allow SSH from specific IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Allow Modbus connections on port 502 from SCADA instance's IP
  ingress {
    from_port   = 502
    to_port     = 502
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Outbound rules 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#------------------------------ EC2 ------------------------------#


# Creation of EC2 instance for SCADA
resource "aws_instance" "workshop_ec2_scada" {
  ami           = "ami-06b21ccaeff8cd686"  # Specified AMI
  instance_type = "t2.micro"               # Specified instance type

  # Assign SCADA Security Group
  vpc_security_group_ids = [aws_security_group.scada_sg.id]

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
yum install -y git python3 python3-pip
pip install flask
yum install -y telnet
EOF
}

# Creation of EC2 instance for PLC
resource "aws_instance" "workshop_ec2_plc" {
  ami                         = "ami-06b21ccaeff8cd686"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.plc_sg.id]
  key_name                    = aws_key_pair.workshop_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.workshop_instance_profile.name

  tags = {
    Name = "workshop-ot-plc-instance"
  }

  # User Data for automatic installation of dependencies
  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y git python3 python3-pip
pip install pymodbus==2.5.3
yum install -y telnet
EOF
}

#------------------------------ IAM ------------------------------#

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

#------------------------------ OUTPUTS VARIABLES ------------------------------#

# Outputs to show the Public IPs and Public DNS of the EC2 instances

output "workshop_ec2_scada_public_ip" {
  value       = aws_instance.workshop_ec2_scada.public_ip
  description = "Public IP of the SCADA EC2 instance"
}

output "workshop_ec2_scada_public_dns" {
  value       = aws_instance.workshop_ec2_scada.public_dns
  description = "Public DNS of the SCADA EC2 instance"
}

output "workshop_ec2_plc_public_ip" {
  value       = aws_instance.workshop_ec2_plc.public_ip
  description = "Public IP of the PLC EC2 instance"
}

output "workshop_ec2_plc_public_dns" {
  value       = aws_instance.workshop_ec2_plc.public_dns
    description = "Public DNS of the PLC EC2 instance"
}