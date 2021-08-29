output "instance_ips" {
    value  ="${aws_instance.web.*.public_ip}"
    
}
output "name_instances" {
    value = "${aws_instance.web.*.tags_name}"
  
}
/*
output "k8s2" {
    value  = "${aws_instance.k8s.public_ip}"
}

output "k8s3" {
    value  = "${aws_instance.k8s.public_ip}"
}

output "instance_ips" {
    value = {
        for instance in aws_instance.web:
        instance.id => instance.public_ip
    }
}

*/