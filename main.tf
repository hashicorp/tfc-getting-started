provider "aws" {
    region = "us-east-1"
    version = "~> 3.0"
  }
terraform {
    backend "s3" {
      bucket = "waynerferreiraaws2"
    #  dynamodb_table = "terraform-state-lock-dynamo"
      key = "terraform-teste.tfstate"
      region = "us-east-1"
      encrypted = true
    }
    required_version = ">= 0.12.25"
}

/*
resource "aws_s3_bucket" "terraform-teste-wayner2" {
    bucket = "waynerferreiraaws2"
    acl = "private"
}

resource "aws_instance" "srvk8s" {
    count = 3
    ami = var.amis["us-east-1"]
    instance_type = "t2.medium"
    tags = {
        Name = "srvk8s${count.index}"
    }
    subnet_id = "subnet-0066472a5254ee7ef"
    vpc_security_group_ids = ["${aws_security_group.sg_teste.id}"]
    key_name = var.key_name
}
*/