# main.tf

provider "aws" {
  region = "us-east-1"  # Cambia esto según la región que prefieras
}

# Crear el par de claves SSH a partir de la clave pública local
resource "aws_key_pair" "workshop_key" {
  key_name   = "workshop_ot_key"
  public_key = file("~/.ssh/id_rsa.pub")  # Asegúrate de tener esta clave pública generada
}

# Security Group para la instancia EC2
resource "aws_security_group" "workshop_sg" {
  name        = "workshop_ot_sg"
  description = "Security Group for OT Workshop EC2 instance"

  # Permitir SSH solo desde la IP específica
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["98.97.134.240/32"]
  }

  # Permitir tráfico en el puerto 502 para simulación de PLC (Modbus)
  ingress {
    from_port   = 502
    to_port     = 502
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Cambia a un rango específico si es posible
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creación de la instancia EC2
resource "aws_instance" "workshop_ec2_scada" {
  ami           = "ami-06b21ccaeff8cd686"  # AMI especificada
  instance_type = "t2.micro"               # Tipo de instancia especificado

  # Asignar Security Group
  vpc_security_group_ids = [aws_security_group.workshop_sg.id]

  # Habilitar IP pública para acceso
  associate_public_ip_address = true

  # Usar el par de claves creado por Terraform
  key_name = aws_key_pair.workshop_key.key_name

  # Etiquetas para identificar recursos
  tags = {
    Name = "workshop-ot-ec2-instance"
  }

  # User Data para instalación automática de dependencias (ejemplo con Python y Git)
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              EOF
}

# IAM Role (opcional si es necesario para permisos adicionales)
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

# Adjuntar el IAM Role a la instancia EC2 (opcional)
resource "aws_iam_instance_profile" "workshop_instance_profile" {
  name = "workshop_instance_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "workshop_ec2_plc" {
  ami                         = "ami-06b21ccaeff8cd686"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.workshop_sg.id]
  key_name                    = aws_key_pair.workshop_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.workshop_instance_profile.name

  tags = {
    Name = "workshop-ot-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              EOF
}
