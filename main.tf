provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "test-vpc"
  }
}
/*==== Subnets ======*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "test-igw"
  }
}
/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}
/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = [aws_subnet.public_subnet1.id,aws_subnet.public_subnet2.id]
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name        = "test_nat"
  }
}
/* Public subnet */
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "test-public-subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1c"
  map_public_ip_on_launch = true
  tags = {
    Name        = "test-public-subnet2"
  }
}
/* Private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false
  tags = {
    Name        = "test-private-subnet"
  }
}
/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "test-private-route-table"
  }
}
/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "test-public-route-table"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
/* Route table associations */
resource "aws_route_table_association" "public" {
  subnet_id      = [aws_subnet.public_subnet1.id,aws_subnet.public_subnet2.id]
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}
/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "default" {
  name        = "test-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags = {
    Environment = "test"
  }
}
# Create a sg for the EC2 instance 
resource "aws_security_group" "instance_security_group" {
  name_prefix = "instance_security_group"
  vpc_id = aws_vpc.vpc.id

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
}

# Create a security group for the ALB
resource "aws_security_group" "alb_security_group" {
  name_prefix = "alb_security_group"
  vpc_id = aws_vpc.vpc.id
  
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
}

# Create an Application Load Balancer
resource "aws_lb" "my_alb" {
  name = "my-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_security_group.id]
  subnets = [aws_subnet.public_subnet1.id,aws_subnet.public_subnet2.id]
  
  tags = {
    Name = "my-alb"
  }
}

# Create a target group for the EC2 instance
resource "aws_lb_target_group" "my_target_group" {
  name = "my-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.my_vpc.id
  
  health_check {
    path = "/health"
    interval = 30
    timeout = 5
  }
  
  tags = {
    Name = "my-target-group"
  }
}

# Create a listener for the ALB
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port = 80
  protocol = "HTTP"
  
  default_action {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    type = "forward"
  }
}

# Create an EC2 instance in the public subnet
resource "aws_instance" "ec2_instance" {
  ami = "ami-02eb7a4783e7e9317"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.public1_subnet.id
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]
  iam_instance_profile= "arn:aws:iam::396558570865:role/ssm"
  associate_public_ip_address= true
  key_name = "my-key"
  tags = {
    Name = "ec2-instance"
  }
}
