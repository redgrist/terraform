provider "aws" {
  region = var.aws_region
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = file(var.ssh_public_key_path)
}

# Security Group: inbound ONLY WireGuard UDP from your public IP
resource "aws_security_group" "wg_only" {
  name        = "${var.name}-wg-only"
  description = "Allow only WG UDP from onprem public IP; no inbound SSH/HTTP"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "WireGuard UDP from onprem"
    from_port   = var.wg_listen_port
    to_port     = var.wg_listen_port
    protocol    = "udp"
    cidr_blocks = [var.onprem_public_ip]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "${var.name}-wg-only" }
}

resource "aws_instance" "wg_client" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.wg_only.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data_wg.sh.tftpl", {
    wg_private_key          = var.wg_private_key
    wg_address              = var.wg_address
    wg_dns                  = var.wg_dns
    wg_peer_public_key      = var.wg_peer_public_key
    wg_preshared_key        = var.wg_preshared_key
    wg_endpoint             = var.wg_endpoint
    wg_endpoint_port        = var.wg_endpoint_port
    wg_allowed_ips          = var.wg_allowed_ips
    wg_persistent_keepalive = var.wg_persistent_keepalive

    data_device_name = var.data_device_name
    mount_point      = var.mount_point
    MP               = var.mount_point
    DEV              = var.data_device_name
  })

  tags = { Name = "${var.name}-wg-client" }
}

# Persistent EBS data volume (NOT deleted automatically)
resource "aws_ebs_volume" "data" {
  availability_zone = var.az
  size              = var.data_volume_size_gb
  type              = "gp3"

  tags = { Name = "${var.name}-data" }
}

resource "aws_volume_attachment" "data_attach" {
  device_name  = var.data_device_name
  volume_id    = aws_ebs_volume.data.id
  instance_id  = aws_instance.wg_client.id
  force_detach = true
}

