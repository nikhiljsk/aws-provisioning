provider "aws" {
  region = "us-east-1"
}

# Key Pair
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = "keypairname"
  public_key = tls_private_key.keypair.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem"
    command = "echo '${tls_private_key.keypair.private_key_pem}' > ./myKey.pem"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "VPC"
  }
}

# Subnets - 6
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet A"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.15.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private Subnet A"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet B"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.16.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private Subnet B"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "Public Subnet C"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.17.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "Private Subnet C"
  }
}

# Internet Gateway for VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main IGW"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip_a" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT EIP A"
  }
}

resource "aws_eip" "nat_eip_b" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT EIP B"
  }
}

resource "aws_eip" "nat_eip_c" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT EIP C"
  }
}

# NAT Gateways for VPC
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "NAT Gateway A"
  }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "NAT Gateway B"
  }
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_eip_c.id
  subnet_id     = aws_subnet.public_c.id

  tags = {
    Name = "NAT Gateway C"
  }
}


# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Association between 3 Public Subnet and 1 Public Route Table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}


# Route Table for Private Subnet
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "Private Route Table A"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "Private Route Table B"
  }
}

resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_c.id
  }

  tags = {
    Name = "Private Route Table C"
  }
}

# Association between Private Subnet and Private Route Table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}
resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private_c.id
}


# Target Group
resource "aws_lb_target_group" "target_s1" {
  name     = "target-s1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "Target Group S1"
  }
}

# Security Group for ALB
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "allow_http"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "tcp"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

# Application Load Balancer
resource "aws_lb" "alb_s" {
  name               = "alb-s"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.public_c.id]

  tags = {
    "Name" = "ALB for S1"
  }
}

# Attach ALB to Target Group
resource "aws_alb_listener" "alb_listen" {
  load_balancer_arn = aws_lb.alb_s.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_s1.arn
    type             = "forward"
  }
}

# SG to allow SSH to Private Subnet Instances
resource "aws_security_group" "allow_ssh_priv" {
  name        = "allow_ssh_priv"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from the bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_priv"
  }
}

# Auto Scaling Groups
resource "aws_launch_template" "template" {
  name_prefix   = "template"
  image_id      = "ami-033b95fb8079dc481"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh_priv.id]

  tags = {
    Name = "Template"
  }
}

resource "aws_autoscaling_group" "asg_s1" {
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  desired_capacity    = 3
  max_size            = 6
  min_size            = 3
  target_group_arns   = ["${aws_lb_target_group.target_s1.arn}"]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG S1"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "asg_s2" {
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  desired_capacity    = 3
  max_size            = 6
  min_size            = 3

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG S2"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "asg_s3" {
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  desired_capacity    = 3
  max_size            = 6
  min_size            = 3

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG S3"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "asg_s4" {
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
  desired_capacity    = 3
  max_size            = 6
  min_size            = 3

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG S4"
    propagate_at_launch = true
  }
}

# SG to allow SSH to Bastion Hosts
resource "aws_security_group" "allow_ssh_pub" {
  name        = "allow_ssh"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_pub"
  }
}

# Bastion Hosts
resource "aws_instance" "bastion_a" {
  ami                         = "ami-033b95fb8079dc481"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_pub.id]
  key_name                    = aws_key_pair.keypair.key_name
  
  user_data = <<-EOL
  #!/bin/bash
  "echo '${tls_private_key.keypair.private_key_pem}' > ./myKey.pem" 
  EOL

  tags = {
    Name = "Bastion Host A"
  }
}

resource "aws_instance" "bastion_b" {
  ami                         = "ami-033b95fb8079dc481"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_b.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_pub.id]
  key_name                    = aws_key_pair.keypair.key_name

  user_data = <<-EOL
  #!/bin/bash
  "echo '${tls_private_key.keypair.private_key_pem}' > ./myKey.pem" 
  EOL

  tags = {
    Name = "Bastion Host B"
  }
}

resource "aws_instance" "bastion_c" {
  ami                         = "ami-033b95fb8079dc481"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_c.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_pub.id]
  key_name                    = aws_key_pair.keypair.key_name

  user_data = <<-EOL
  #!/bin/bash
  "echo '${tls_private_key.keypair.private_key_pem}' > ./myKey.pem" 
  EOL

  tags = {
    Name = "Bastion Host C"
  }
}