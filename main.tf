provider "aws" {
  region = "us-east-1" 
}

#VPC

resource "aws_vpc" "VPC" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# Define CIDR blocks for public and private subnets
locals {
  public_cidrs = {
    "az1" = "10.0.0.0/24"
    "az2" = "10.0.1.0/24"
    "az3" = "10.0.2.0/24"
  }
  
  private_cidrs = {
    "az1" = "10.0.3.0/24"
    "az2" = "10.0.4.0/24"
    "az3" = "10.0.5.0/24"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each = var.vpc_azs

  vpc_id            = aws_vpc.VPC.id
  cidr_block        = local.public_cidrs[each.key]  # Use local variable for CIDR
  availability_zone = each.value
  map_public_ip_on_launch = true  # Enable public IP for public subnets

  tags = {
    Name = "${var.vpc_name}-Public-Subnet-${each.value}"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = var.vpc_azs

  vpc_id            = aws_vpc.VPC.id
  cidr_block        = local.private_cidrs[each.key]  # Use local variable for CIDR
  availability_zone = each.value
  map_public_ip_on_launch = false  # Disable public IP for private subnets

  tags = {
    Name = "${var.vpc_name}-Private-Subnet-${each.value}"
  }
}



# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "${var.vpc_name}-Public-Route-Table"
  }
}

# Public Route Table Association (for Public Subnets)
resource "aws_route_table_association" "public_subnet_assoc" {
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "${var.vpc_name}-Private-Route-Table"
  }
}

# Private Route Table Association (for Private Subnets)
resource "aws_route_table_association" "private_subnet_assoc" {
  for_each = aws_subnet.private_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}


# Internet Gateway (for Public Route Table)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "${var.vpc_name}-IG"
  }
}



# Route for Public Route Table (to Internet Gateway)
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.vpc_name}-NAT-EIP"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet["az1"].id  # Use one of the public subnets

  tags = {
    Name = "${var.vpc_name}-NAT-Gateway"
  }
}

# Route for Private Route Table (to NAT Gateway)
resource "aws_route" "private_route_to_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}