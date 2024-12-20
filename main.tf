provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "VPC" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# Fetch available availability zones in the specified region
data "aws_availability_zones" "available" {}

# Define CIDR blocks for public and private subnets dynamically
locals {
  public_cidrs = { for i, az in data.aws_availability_zones.available.names : 
                    az => cidrsubnet(var.vpc_cidr, 8, i) }
  
  private_cidrs = { for i, az in data.aws_availability_zones.available.names : 
                     az => cidrsubnet(var.vpc_cidr, 8, i + length(data.aws_availability_zones.available.names)) }
}

# Public Subnets
resource "aws_subnet" "public_subnet" {
  for_each = toset(data.aws_availability_zones.available.names)  # Convert list to set

  vpc_id            = aws_vpc.VPC.id
  cidr_block        = local.public_cidrs[each.value]  # Use local variable for CIDR
  availability_zone = each.value
  map_public_ip_on_launch = true  # Enable public IP for public subnets

  tags = {
    Name = "${var.vpc_name}-Public-Subnet-${each.value}"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  for_each = toset(data.aws_availability_zones.available.names)  # Convert list to set

  vpc_id            = aws_vpc.VPC.id
  cidr_block        = local.private_cidrs[each.value]  # Use local variable for CIDR
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
  subnet_id     = aws_subnet.public_subnet[data.aws_availability_zones.available.names[0]].id  # Use the first public subnet ID

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