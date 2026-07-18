#################################
# Latest Amazon Linux 2023 AMI
#################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#################################
# VPC
#################################

resource "aws_vpc" "k8s_vpc" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

#################################
# Internet Gateway
#################################

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#################################
# Public Subnet
#################################

resource "aws_subnet" "public_subnet" {

  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

#################################
# Route Table
#################################

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.k8s_vpc.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

#################################
# Route Association
#################################

resource "aws_route_table_association" "public_assoc" {

  subnet_id = aws_subnet.public_subnet.id

  route_table_id = aws_route_table.public_rt.id
}

#################################
# Security Group
#################################

resource "aws_security_group" "k8s_sg" {

  name = "${var.project_name}-sg"

  description = "Allow All"

  vpc_id = aws_vpc.k8s_vpc.id

  ingress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = "${var.project_name}-sg"

  }
}

#################################
# EC2 List
#################################

locals {

  instances = {

    haproxy = "haproxy"

    master1 = "master1"

    master2 = "master2"

    worker1 = "worker1"

    worker2 = "worker2"

  }
}

#################################
# EC2 Instances
#################################

resource "aws_instance" "nodes" {

  for_each = local.instances

  ami = data.aws_ami.amazon_linux.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.k8s_sg.id
  ]

  key_name = var.key_name

  associate_public_ip_address = true

  tags = {

    Name = each.value

  }

}
