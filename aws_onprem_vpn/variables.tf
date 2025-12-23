variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "az" {
  type    = string
  default = "eu-central-1a"
}

variable "name" {
  type    = string
  default = "opnsense-s2s"
}

variable "onprem_cidr" {
  type    = string
  default = "192.168.22.0/24"
}

# Twój PUBLICZNY IP (Customer Gateway) – WAN OPNsense
variable "onprem_public_ip" {
  type        = string
  description = "31.178.13.215"
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.50.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.50.10.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# Ścieżka do publicznego klucza SSH do EC2
variable "ssh_public_key_path" {
  type        = string
  description = "/home/redgrist/.ssh/aws_test_ed25519.pub"
}
