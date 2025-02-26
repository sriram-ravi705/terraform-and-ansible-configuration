provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "sg" {
  tags = {
    "Name"="security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.sg.id
  from_port = 22
  to_port = 22
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.sg.id
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.sg.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_traffic" {
    security_group_id = aws_security_group.sg.id
    ip_protocol = -1
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_instance" "aws" {
  ami             = "ami-04b4f1a9cf54c11d0"
  instance_type   = "t2.micro"
  key_name        = "ansible_key"
  security_groups  = [aws_security_group.sg.name]
  associate_public_ip_address = true
  tags = {
    Name = "Terraform_Instance"
  }
}

resource "null_resource" "name" {
  provisioner "remote-exec" {
    connection {
      host        = "3.91.197.139"
      user        = "ubuntu"
      private_key = file("${path.module}/private_key.pem")
      type        = "ssh"
    }
    inline = [
        "sudo echo '${aws_instance.aws.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=ansible_key.pem' >> /home/ubuntu/new_hosts",
        "echo '${file("${path.module}/deploy.yaml")}' > /home/ubuntu/deploy.yaml",
        "ansible-playbook -i new_hosts deploy.yaml"
    ]
  }
}