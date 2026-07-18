output "public_ips" {

  value = {

    for name, instance in aws_instance.nodes :

    name => instance.public_ip

  }

}

output "private_ips" {

  value = {

    for name, instance in aws_instance.nodes :

    name => instance.private_ip

  }

}

output "vpc_id" {

  value = aws_vpc.k8s_vpc.id

}
