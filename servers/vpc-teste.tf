resource "aws_vpc" "vpcteste" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpcteste"
  }
}
resource "aws_subnet" "subnet-testeA" {
  vpc_id     = "${var.vpcteste}"
  cidr_block = "10.0.1.0/24"
  availability_zone_id = "use1-az2"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-testeA"
  }
}
resource "aws_subnet" "subnet-testeB" {
  vpc_id     = "${var.vpcteste}"
  cidr_block = "10.0.2.0/24"
  availability_zone_id = "use1-az4"
  
  tags = {
    Name = "subnet-testeB"
  }
}

resource "aws_network_acl" "acl_teste" {
  vpc_id = "${var.vpcteste}"
  subnet_ids = [aws_subnet.subnet-testeA.id]
    tags = {
    name = "acl_teste"
  }
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }


egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
    ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
    ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
     
}

resource "aws_internet_gateway" "igw-teste" {
    vpc_id = "${var.vpcteste}"

    tags = {
      Name = "igw-teste"
    }
}    
resource "aws_route_table" "rt-teste" {
  vpc_id = "${var.vpcteste}"
  tags = {
    Name = "rt-teste"
  }
}
resource "aws_route" "rotas-teste" {
  route_table_id = "${aws_route_table.rt-teste.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw-teste.id}"

  depends_on = [aws_route_table.rt-teste]
}
resource "aws_route_table_association" "rt-subnet-testeA" {
  subnet_id = "subnet-0ba91aa09bd8cfbbf"
  route_table_id = "rtb-0ac57c12707d5e993"

 }

