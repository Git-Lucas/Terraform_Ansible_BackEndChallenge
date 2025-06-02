terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket         = "s3-bucket-125675"
    key            = "terraform/backendchallenge/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = "us-east-1"
}


resource "aws_security_group" "backendchallenge_sg" {
  name        = "backendchallenge_sg"
  description = "Security group for BackEndChallenge_App"

  # Inbound rules
  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # usar o IP fixo do time/local
  }

  ingress {
    description      = "Allow HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # Outbound rules (allow all by default)
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BackEndChallenge_SG"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow SQL Server access from EC2"

  # Inbound rules
  ingress {
    description      = "SQL Server from EC2 App SG"
    from_port        = 1433
    to_port          = 1433
    protocol         = "tcp"
    security_groups  = [aws_security_group.backendchallenge_sg.id]
  }

  # Outbound rules (allow all by default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS_SG"
  }
}


resource "aws_instance" "backendchallenge_app" {
  ami                    = "ami-0e2c8caa4b6378d8c"
  instance_type          = "t2.micro"
  key_name               = "back-end_challenge_20210221"
  vpc_security_group_ids = [aws_security_group.backendchallenge_sg.id]

  tags = {
    Name = "BackEndChallenge_App"
  }
}

resource "aws_db_instance" "sqlserver" {
  allocated_storage      = 20
  engine                 = "sqlserver-ex"
  engine_version         = "16.00"
  instance_class         = "db.t3.micro"
  username               = "SA"
  password               = "BackEndChallenge20210221"
  port                   = 1433
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "SqlServer"
  }
}


output "instance_public_ip" {
  value = aws_instance.backendchallenge_app.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.sqlserver.endpoint
}
output "rds_username" {
  value = aws_db_instance.sqlserver.username
}
output "rds_password" {
  value = aws_db_instance.sqlserver.password
  sensitive = true
}