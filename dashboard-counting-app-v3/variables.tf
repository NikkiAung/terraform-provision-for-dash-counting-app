variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "project_name" {
  description = "Prefix used in all resource names and tags"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

# ← CHANGED: list of strings instead of single string
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

# ← CHANGED: list of strings instead of single string
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

# ← CHANGED: list of strings instead of two separate variables
variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "my_ip" {
  description = "Your local IP for SSH access to bastion (x.x.x.x/32)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for both servers"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to create"
  type        = string
}