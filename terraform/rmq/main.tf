provider "aws" {
  region  = "us-east-1"
  profile = var.profile
}

resource "aws_instance" "rmq" {
  ami                    = "ami-07ebfd5b3428b6f4d"
  instance_type          = "t2.micro"
  key_name               = "rabbitmq"
  vpc_security_group_ids = ["sg-0b27f815d2e3a2436"]

  tags = {
    Name  = var.name
    group = var.group
  }
}