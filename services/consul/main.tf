provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name = "example.com"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_vpc_dhcp_options_association" "main" {
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "main" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.5.0/24"
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id = "${aws_vpc.main.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route53_zone" "main" {
  name = "example.com"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group" "allow_all_internal" {
  name = "allow_all_internal"
  description = "Allow all inbound traffic from internal"

  vpc_id = "${aws_vpc.main.id}"

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "allow_ssh_public" {
  name = "allow_ssh_public"
  description = "Allow SSH from public"

  vpc_id = "${aws_vpc.main.id}"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami = "${var.bastion_ami}"
  instance_type = "t1.micro"
  key_name = "${var.key_name}"
  
  subnet_id = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_public.id}"]

  associate_public_ip_address = true
}

resource "aws_instance" "consul" {
  ami = "${var.consul_ami}"
  instance_type = "t1.micro"
  key_name = "${var.key_name}"

  subnet_id = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_all_internal.id}"]

  count = 3

  user_data = "#!/bin/bash\nansible-playbook /ansible/playbook.yml --tags configure"
}

resource "aws_route53_record" "consul_ns" {
  zone_id = "${aws_route53_zone.main.id}"
  name = "consul.example.com"
  type = "NS"
  ttl = "30"
  records = [
    "${aws_instance.consul.0.private_ip}",
    "${aws_instance.consul.1.private_ip}",
    "${aws_instance.consul.2.private_ip}"
  ]
}

resource "aws_route53_record" "consul_bootstrap_a" {
  zone_id = "${aws_route53_zone.main.id}"
  name = "consul-bootstrap.example.com"
  type = "A"
  ttl = "30"
  records = [
    "${aws_instance.consul.0.private_ip}",
    "${aws_instance.consul.1.private_ip}",
    "${aws_instance.consul.2.private_ip}"
  ]
}

output "bastion_public_dns" {
  value = "${aws_instance.bastion.public_dns}"
}
