variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "name" {
  type        = string
  description = "Name prefix for resources"
  default     = "aws-wg-client"
}

variable "az" {
  type        = string
  description = "Availability Zone for subnet/instance"
  default     = "eu-central-1a"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.50.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR"
  default     = "10.50.10.0/24"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to your SSH public key"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to your SSH private key (only for your local use, not sent to AWS)"
  default     = ""
}

# --- WireGuard client config (EC2) ---
variable "wg_private_key" {
  type        = string
  description = "WireGuard private key for EC2 client (keep secret)"
  sensitive   = true
}

variable "wg_address" {
  type        = string
  description = "WireGuard IP for EC2 client, e.g. 10.0.0.5/32"
  default     = "10.0.0.5/32"
}

variable "wg_dns" {
  type        = string
  description = "DNS pushed/used on client when tunnel is up"
  default     = "1.1.1.1"
}

variable "wg_peer_public_key" {
  type        = string
  description = "WireGuard public key of your OPNsense (server)"
}

variable "wg_preshared_key" {
  type        = string
  description = "Optional preshared key (recommended)"
  sensitive   = true
  default     = ""
}

variable "wg_endpoint" {
  type        = string
  description = "OPNsense public endpoint host/IP (without port), e.g. 31.x.x.x"
}

variable "wg_listen_port" {
  type        = number
  description = "WireGuard listen port on EC2 client (for return traffic)"
  default     = 51820
}

variable "wg_endpoint_port" {
  type        = number
  description = "WireGuard port on OPNsense server"
  default     = 51821
}

variable "wg_allowed_ips" {
  type        = string
  description = "AllowedIPs for peer. For full-tunnel use 0.0.0.0/0,::/0"
  default     = "0.0.0.0/0,::/0"
}

variable "wg_persistent_keepalive" {
  type        = number
  description = "Keepalive in seconds (good behind NAT)"
  default     = 25
}

# --- Security: allow only WG UDP from your home/public IP ---
variable "onprem_public_ip" {
  type        = string
  description = "Your public IP (or OPNsense WAN IP) allowed to send WG UDP to EC2, e.g. 31.178.13.215/32"
}

# --- Persistent data disk ---
variable "data_volume_size_gb" {
  type        = number
  description = "EBS data volume size"
  default     = 20
}

variable "data_device_name" {
  type        = string
  description = "Linux device name for attached EBS"
  default     = "/dev/xvdb"
}

variable "mount_point" {
  type        = string
  description = "Mount point for data volume"
  default     = "/data"
}

