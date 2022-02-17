provider "aws" {
  region = "us-east-1"
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
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet A"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.15.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private Subnet A"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet B"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.16.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private Subnet B"
  }
}

resource "aws_subnet" "public_c" {
    vpc_id     = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1c"
  
    tags = {
      Name = "Public Subnet C"
    }
  }
  
  resource "aws_subnet" "private_c" {
    vpc_id     = aws_vpc.main.id
    cidr_block = "10.0.17.0/24"
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
