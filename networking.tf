#########################################################
# Availability Zones
#########################################################

data "aws_availability_zones" "available" {
  state = "available"
}

#########################################################
# DP VPC
#########################################################

resource "aws_vpc" "dp_vpc" {

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dp-vpc"
  }
}

#########################################################
# Public Subnets
# Used by internet-facing AWS load balancers
#########################################################

resource "aws_subnet" "public" {

  for_each = var.public_subnets

  vpc_id                  = aws_vpc.dp_vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name                     = "dp-public-${each.key}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  }
}

#########################################################
# Private Subnets
# Used by EKS worker nodes and internal load balancers
#########################################################

resource "aws_subnet" "private" {

  for_each = var.private_subnets

  vpc_id            = aws_vpc.dp_vpc.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name                              = "dp-private-${each.key}"
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

#########################################################
# Internet Gateway
#########################################################

resource "aws_internet_gateway" "dp_igw" {

  vpc_id = aws_vpc.dp_vpc.id

  tags = {
    Name = "dp-igw"
  }
}

#########################################################
# Public Route Table
#########################################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.dp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dp_igw.id
  }

  tags = {
    Name = "dp-public-route-table"
  }
}

#########################################################
# Public Subnet Route Table Associations
#########################################################

resource "aws_route_table_association" "public_2a" {

  subnet_id      = aws_subnet.public["us-east-2a"].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2b" {

  subnet_id      = aws_subnet.public["us-east-2b"].id
  route_table_id = aws_route_table.public.id
}

#########################################################
# NAT Gateway Elastic IP
# Ephemeral - controlled by enable_eks_runtime
#########################################################

resource "aws_eip" "nat" {

  count = var.enable_eks_runtime ? 1 : 0

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-nat-eip"
      Component = "Networking"
      Role      = "NAT Gateway Elastic IP"
    }
  )
}

#########################################################
# NAT Gateway
# Cost-optimized Project 1 design: single NAT Gateway
# Ephemeral - controlled by enable_eks_runtime
#########################################################

resource "aws_nat_gateway" "dp_nat" {

  count = var.enable_eks_runtime ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public["us-east-2a"].id

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-nat-gateway"
      Component = "Networking"
      Role      = "Private Subnet Internet Egress"
    }
  )

  depends_on = [
    aws_internet_gateway.dp_igw
  ]
}

#########################################################
# Private Route Table
# Ephemeral because its default route depends on NAT
#########################################################

resource "aws_route_table" "private" {

  count = var.enable_eks_runtime ? 1 : 0

  vpc_id = aws_vpc.dp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dp_nat[0].id
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-private-route-table"
      Component = "Networking"
      Role      = "Private Subnet Routing"
    }
  )
}

#########################################################
# Private Subnet Route Table Associations
# Ephemeral - created with EKS runtime
#########################################################

resource "aws_route_table_association" "private_2a" {

  count = var.enable_eks_runtime ? 1 : 0

  subnet_id      = aws_subnet.private["us-east-2a"].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "private_2b" {

  count = var.enable_eks_runtime ? 1 : 0

  subnet_id      = aws_subnet.private["us-east-2b"].id
  route_table_id = aws_route_table.private[0].id
}