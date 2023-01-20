provider "aws" {
    region="us-east-1"
    profile=Admin
}

resource "aws_instance" "rmq" {
    ami = "ami-07ebfd5b3428b6f4d"
    instance_type = "t2_micro"
    key_name = "rabbitmq"
    vpc_security_group_ids = ["sg-0b27f815d2e3a2436"]

    tags = {
        name = var.name
        group = var.group
    }
}