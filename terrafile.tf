module "servers" {
    source = "./servers"
    servers = 0
}
output "instance_ips" {
    value  = "${module.servers.instance_ips}"
}

/*
module "web_server_sg" {
  source = "./servers"

  name        = "web-server"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = "${var.vpcteste}"

  ingress_cidr_blocks = ["10.10.0.0/16"]
}
*/