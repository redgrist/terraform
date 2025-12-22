terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# VPC + SUBNETS
# -------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public" }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-private" }
}

# -------------------------
# IGW + PUBLIC ROUTES
# -------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# NAT GATEWAY (płatny)
# -------------------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "${var.name}-nat" }

  depends_on = [aws_internet_gateway.igw]
}

# -------------------------
# PRIVATE ROUTES (NAT + VPN)
# -------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private-rt" }
}

# internet z private przez NAT
resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# -------------------------
# VPN: VGW + CGW + VPN Connection
# -------------------------
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-vgw" }
}

resource "aws_customer_gateway" "cgw" {
  bgp_asn    = 65000
  ip_address = var.onprem_public_ip
  type       = "ipsec.1"
  tags       = { Name = "${var.name}-cgw-opnsense" }
}

resource "aws_vpn_connection" "vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.cgw.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags                = { Name = "${var.name}-vpn" }
}

resource "aws_vpn_connection_route" "to_onprem" {
  vpn_connection_id      = aws_vpn_connection.vpn.id
  destination_cidr_block = var.onprem_cidr
}

# Trasa do on-prem w PRIVATE route table przez VGW
resource "aws_route" "private_to_onprem" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.onprem_cidr
  gateway_id             = aws_vpn_gateway.vgw.id
}

# -------------------------
# EC2 (mini) tylko po VPN
# -------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "vpn_only" {
  name        = "${var.name}-vpn-only"
  description = "Allow access only from on-prem via VPN"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from on-prem"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr]
  }

  ingress {
    description = "ICMP ping from on-prem"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.onprem_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-vpn-only" }
}

resource "aws_instance" "vpn_host" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.vpn_only.id]
  key_name               = aws_key_pair.this.key_name

  associate_public_ip_address = false

  tags = { Name = "${var.name}-ec2-vpn" }
}

# -------------------------
# Outputs
# -------------------------
output "ec2_private_ip" {
  value = aws_instance.vpn_host.private_ip
}

output "vpn_connection_id" {
  value = aws_vpn_connection.vpn.id
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

