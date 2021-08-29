resource "aws_instance" "web" {
   count = "${var.servers}"
    ami = "ami-07d02ee1eeb0c996c"
    instance_type = "t2.micro"

   /*dynamic "ebs_block_device"{
        for_each = "${var.blocks}" 
        content {
            device_name = ebs_block_device.value["device_name"]
            volume_size = ebs_block_device.value["volume_size"]
            volume_type = ebs_block_device.value["volume_type"]
        }
    }*/


    tags = {
       # Name = "k8s"
        Name = "k8s${count.index}"
    }
    subnet_id = "${var.subnet-testeA}"
    vpc_security_group_ids = ["${aws_security_group.sg_teste.id}"]
    key_name = "${var.key_name}"
}


/*
resource "aws_instance" "web" {
    ami = "ami-07d02ee1eeb0c996c"
    for_each = toset(var.instance_type)

    instance_type = each.value
    tags = {
        Name = "k8s"
        #Name = "HAPROXY${count.index}"
    }

    dynamic "ebs_block_device"{
        for_each = var.blocks
        content {
            device_name = ebs_block_device.value["device_name"]
            volume_size = ebs_block_device.value["volume_size"]
            volume_type = ebs_block_device.value["volume_type"]
        }
    }
    subnet_id = "${var.subnet-testeA}"
    vpc_security_group_ids = ["${aws_security_group.sg_teste.id}"]
    key_name = "${var.key_name}"
}

/*data "aws_ami" "k8s"{
    most_recent = true

    filter {
        name = "name"
        values = [""]
    }
}
resource "aws_instance" "k8s" {
    count = 3
    ami = data.aws_ami.k8s.id
    instance_type = "t2.medium"
    tags = {
        Name = "k8s${count.index}"
    }
    subnet_id = "subnet-0066472a5254ee7ef"
    vpc_security_group_ids = ["${aws_security_group.sg_teste.id}"]
    key_name = var.key_name
}


resource "aws_instance" "k8s" {
    count = 1
    ami = var.amis["us-east-1"]
    instance_type = "t2.medium"
    tags = {
        Name = "k8s${count.index}"
    }
    subnet_id = "subnet-0066472a5254ee7ef"
    vpc_security_group_ids = ["${aws_security_group.sg_teste.id}"]
    key_name = var.key_name
}
*/