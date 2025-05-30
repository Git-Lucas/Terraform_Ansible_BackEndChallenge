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
    cidr_blocks      = ["0.0.0.0/0"]
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

resource "aws_instance" "backendchallenge_app" {
  ami           = "ami-0e2c8caa4b6378d8c"
  instance_type = "t2.micro"
  key_name = "back-end_challenge_20210221"
  vpc_security_group_ids = [aws_security_group.backendchallenge_sg.id]

  tags = {
    Name = "BackEndChallenge_App"
  }
}

output "instance_public_ip" {
  value = aws_instance.backendchallenge_app.public_ip
}
