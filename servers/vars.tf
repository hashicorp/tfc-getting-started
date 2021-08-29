variable "amis" {
    #type = map
    default = {
        "us-east-1" = "ami-08b2293fdd2deba2a"
        "us-east-2" = "ami-089fe97bc00bff7cc"
    }
}

variable "cdirs_acesso_remoto" {
    default = ["0.0.0.0/0"]
}
variable "vpcteste" {
    default = "vpc-078756f533829c25a"
}
variable "subnet-testeA"{
    default = "subnet-0ba91aa09bd8cfbbf"
}
variable "subnet-testeB"{
    default = "subnet-017d24f156c0dc554"
}

variable "sg_teste" {
    #type = map
#   description = "sg-0714a8294df4cb3ad"
    default = {
    aws_security_group = "sg-0714a8294df4cb3ad"
    }
}

variable "key_name" {
    default = "chaveaws-local"
}

variable "servers" {

}
/*
variable "blocks" {
    type = list (object({
        device_name = string
        volume_size = string
        volume_type = string
    }))
    description = "List of EBS block"
}
*/
/*
variable "name_instances" {
  #  type = string
    default = "k8s"
    description = "Nome das instancias EC2"
}
/*
variable "instance_type"{
    type = list (string)
    default = ["t2.micro","t3.medium"] 
    description = "The list of instance type"
}
*/