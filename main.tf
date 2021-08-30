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

/*resource "fakewebservices_vpc" "primary_vpc" {
  name       = "Primary VPC"
  cidr_block = "0.0.0.0/1"
}

resource "fakewebservices_server" "servers" {
  count = 2

  name = "Server ${count.index + 1}"
  type = "t2.micro"
  vpc  = fakewebservices_vpc.primary_vpc.name
}

resource "fakewebservices_load_balancer" "primary_lb" {
  name    = "Primary Load Balancer"
  servers = fakewebservices_server.servers[*].name
}

resource "fakewebservices_database" "prod_db" {
  name = "Production DB"
  size = 256
}
*/