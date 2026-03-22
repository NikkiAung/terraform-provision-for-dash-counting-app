variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "public_az" {
  description = "AZ for the public subnet (bastion lives here)"
  type        = string
}

variable "private_az" {
  description = "AZ for the private subnet (app server lives here)"
  type        = string
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

variable "project_name" {
  description = "Prefix used in all resource names"
  type        = string
}