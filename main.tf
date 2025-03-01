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

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.sg.id
  from_port = 3000
  to_port = 3000
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

  provisioner "file" {
    source = "${path.module}/private_key.pem"
    destination = "/home/ubuntu/ansible_key.pem"
  }
  connection {
      host        = aws_instance.aws.public_ip
      user        = "ubuntu"
      private_key = file("${path.module}/private_key.pem")
      type        = "ssh"
  }
}

resource "null_resource" "name" {
  provisioner "remote-exec" {
    connection {
      host        = aws_instance.aws.public_ip
      user        = "ubuntu"
      private_key = file("${path.module}/private_key.pem")
    }
    
    inline = [
        "sudo apt update",
        "sudo apt install software-properties-common",
        "sudo add-apt-repository --yes --update ppa:ansible/ansible",
        "sudo apt install ansible -y",
        # "sudo cp ${path.module}/private_key.pem  /home/ubuntu/ansible_key.pem",
        "sudo chmod 400 /home/ubuntu/ansible_key.pem",
        "sudo echo '[defaults]' > /home/ubuntu/ansible.cfg",
        "sudo echo 'host_key_checking = False' >> /home/ubuntu/ansible.cfg",
        "touch /home/ubuntu/new_hosts",
        "sudo echo '${aws_instance.aws.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/ansible_key.pem' >> /home/ubuntu/new_hosts",
        "echo '${file("${path.module}/deploy.yaml")}' > /home/ubuntu/deploy.yaml",
        "ansible-playbook -i new_hosts deploy.yaml"
    ]
  }
}