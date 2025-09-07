##############################################
# Definizione subnets common                 #
##############################################

locals {
  subnets = [
    { name = "pub-sub-1a", cidr = "172.20.1.0/24", az = "a", tier = "alb", public = true },
    { name = "pub-sub-2b", cidr = "172.20.2.0/24", az = "b", tier = "alb", public = true },
    { name = "pri-sub-3a", cidr = "172.20.3.0/24", az = "a", tier = "web", public = false },
    { name = "pri-sub-4b", cidr = "172.20.4.0/24", az = "b", tier = "web", public = false },
    { name = "pri-sub-5a", cidr = "172.20.5.0/24", az = "a", tier = "app", public = false },
    { name = "pri-sub-6b", cidr = "172.20.6.0/24", az = "b", tier = "app", public = false },
    { name = "pri-sub-7a", cidr = "172.20.7.0/24", az = "a", tier = "db", public = false },
    { name = "pri-sub-8b", cidr = "172.20.8.0/24", az = "b", tier = "db", public = false },
  ]

  # mappatura AZ per us-west-1: a → b, b → c
  az_map_secondary = {
    a = "b"
    b = "c"
  }
}

##############################################
# VPC e risorse core                         #
##############################################

# Production (us-east-1)
resource "aws_vpc" "prod" {
  provider             = aws.primary
  cidr_block           = "172.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-prod" }
}

resource "aws_internet_gateway" "prod_igw" {
  provider = aws.primary
  vpc_id   = aws_vpc.prod.id
  tags     = { Name = "igw-prod" }
}

resource "aws_route_table" "prod_public_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.prod.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod_igw.id
  }
  tags = { Name = "rt-prod-public" }
}

# DR (us-west-1)
resource "aws_vpc" "dr" {
  provider             = aws.secondary
  cidr_block           = "172.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc-dr" }
}

resource "aws_internet_gateway" "dr_igw" {
  provider = aws.secondary
  vpc_id   = aws_vpc.dr.id
  tags     = { Name = "igw-dr" }
}

resource "aws_route_table" "dr_public_rt" {
  provider = aws.secondary
  vpc_id   = aws_vpc.dr.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr_igw.id
  }
  tags = { Name = "rt-dr-public" }
}

##############################################
# Subnets                                    #
##############################################

# Production subnets
resource "aws_subnet" "prod" {
  provider                = aws.primary
  for_each                = { for s in local.subnets : s.name => s }
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = each.value.cidr
  availability_zone       = "${var.aws_region_primary}${each.value.az}"
  map_public_ip_on_launch = each.value.public
  tags                    = { Name = each.value.name, Tier = each.value.tier }
}

# DR subnets
resource "aws_subnet" "dr" {
  provider                = aws.secondary
  for_each                = { for s in local.subnets : s.name => s }
  vpc_id                  = aws_vpc.dr.id
  cidr_block              = each.value.cidr
  availability_zone       = "${var.aws_region_secondary}${local.az_map_secondary[each.value.az]}"
  map_public_ip_on_launch = each.value.public
  tags                    = { Name = each.value.name, Tier = each.value.tier }
}

variable "aws_region_secondary" {
  description = "The AWS region for the secondary (DR) environment"
  type        = string
}

##############################################
# Associazioni route table pubbliche         #
##############################################

# Prod
resource "aws_route_table_association" "prod_pub_assoc" {
  provider       = aws.primary
  for_each       = { for s in local.subnets : s.name => s if s.public }
  subnet_id      = aws_subnet.prod[each.key].id
  route_table_id = aws_route_table.prod_public_rt.id
}

# DR
resource "aws_route_table_association" "dr_pub_assoc" {
  provider       = aws.secondary
  for_each       = { for s in local.subnets : s.name => s if s.public }
  subnet_id      = aws_subnet.dr[each.key].id
  route_table_id = aws_route_table.dr_public_rt.id
}

##############################################
# NAT Gateway + private route tables         #
##############################################

# Prod NAT
resource "aws_eip" "prod_nat_eip" {
  provider = aws.primary
  domain   = "vpc"
  tags     = { Name = "eip-prod-nat" }
}

resource "aws_nat_gateway" "prod_nat" {
  provider      = aws.primary
  allocation_id = aws_eip.prod_nat_eip.id
  subnet_id     = aws_subnet.prod["pub-sub-1a"].id
  depends_on    = [aws_internet_gateway.prod_igw]
  tags          = { Name = "nat-prod" }
}

resource "aws_route_table" "prod_private_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.prod.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.prod_nat.id
  }
  tags = { Name = "rt-prod-private" }
}

resource "aws_route_table_association" "prod_priv_assoc" {
  provider       = aws.primary
  for_each       = { for s in local.subnets : s.name => s if !s.public }
  subnet_id      = aws_subnet.prod[each.key].id
  route_table_id = aws_route_table.prod_private_rt.id
}

# DR NAT
resource "aws_eip" "dr_nat_eip" {
  provider = aws.secondary
  domain   = "vpc"
  tags     = { Name = "eip-dr-nat" }
}

resource "aws_nat_gateway" "dr_nat" {
  provider      = aws.secondary
  allocation_id = aws_eip.dr_nat_eip.id
  subnet_id     = aws_subnet.dr["pub-sub-1a"].id
  depends_on    = [aws_internet_gateway.dr_igw]
  tags          = { Name = "nat-dr" }
}

resource "aws_route_table" "dr_private_rt" {
  provider = aws.secondary
  vpc_id   = aws_vpc.dr.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dr_nat.id
  }
  tags = { Name = "rt-dr-private" }
}

resource "aws_route_table_association" "dr_priv_assoc" {
  provider       = aws.secondary
  for_each       = { for s in local.subnets : s.name => s if !s.public }
  subnet_id      = aws_subnet.dr[each.key].id
  route_table_id = aws_route_table.dr_private_rt.id
}
