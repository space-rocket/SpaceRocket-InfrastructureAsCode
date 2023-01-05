locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

resource "random_id" "random" {
  byte_length = 2
}

resource "aws_vpc" "sre_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "sre_vpc-${random_id.random.id}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "sre_internet_gateway" {
  vpc_id = aws_vpc.sre_vpc.id

  tags = {
    Name = "sre_igw"
  }
}

resource "aws_route_table" "sre_public_rt" {
  vpc_id = aws_vpc.sre_vpc.id

  tags = {
    Name = "sre-public"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.sre_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sre_internet_gateway.id
}

resource "aws_default_route_table" "sre_private_rt" {
  default_route_table_id = aws_vpc.sre_vpc.default_route_table_id

  tags = {
    Name = "sre_private"
  }
}

resource "aws_subnet" "sre_public_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.sre_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "sre_public_${count.index + 1}"
  }
}

resource "aws_subnet" "sre_private_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.sre_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + length(local.azs))
  map_public_ip_on_launch = false
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "sre_private_${count.index + 1}"
  }
}

resource "aws_route_table_association" "sre_public_assoc" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.sre_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.sre_public_rt.id
}

resource "aws_security_group" "sre_sg" {
  name        = "public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.sre_vpc.id
}

resource "aws_security_group" "sre_alb_sg" {
  name        = "alb_sg"
  description = "Security group for alb to communicate with app instances"
  vpc_id      = aws_vpc.sre_vpc.id
  
  ingress {
    description      = "Allow ALB access on port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "Allow ALB access on port 80"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "sre_app_sg" {
  name        = "app_sg"
  description = "Security group for app instances"
  vpc_id      = aws_vpc.sre_vpc.id
  
  ingress {
    description      = "allow ssh from cloud9 instance"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.cloud9_ip]
  }
  
  ingress {
    description      = "Allow ALB access on port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.sre_alb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_db_subnet_group" "sre_db_subnet_group" {
  name       = "sre_db"
  subnet_ids = aws_subnet.sre_public_subnet.*.id

  tags = {
    Name = "sre_db_subnet_group"
  }
}

resource "aws_security_group" "sre_db_security_group" {
  name   = "sre_db_security_group"
  vpc_id = aws_vpc.sre_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sre_db_security_group"
  }
}
