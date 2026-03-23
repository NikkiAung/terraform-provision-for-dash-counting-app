# ─────────────────────────────────────────
# VPC MODULE
# Replaces: vpc.tf + igw.tf + subnets.tf
#           nat-gateway.tf + route-tables.tf
# Source: terraform-aws-modules/vpc/aws
# ─────────────────────────────────────────

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # ── Basic VPC config ──────────────────
  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  # ── Subnets + AZs ────────────────────
  azs             = var.azs
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # ── Internet Gateway ──────────────────
  # Automatically creates and attaches IGW
  # to the VPC when public subnets are defined
  create_igw = true

  # ── NAT Gateway ───────────────────────
  enable_nat_gateway = true

  # one NAT gateway shared across all private subnets
  # false = one NAT per AZ (expensive, for production)
  single_nat_gateway = true

  # ── DNS ───────────────────────────────
  enable_dns_hostnames = true
  enable_dns_support   = true

  # ── Public subnet behavior ────────────
  # Instances in public subnet get public IP automatically
  map_public_ip_on_launch = true

  # ── Tags ──────────────────────────────
  tags = {
    Project = var.project_name
  }

  public_subnet_tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "public"
  }

  private_subnet_tags = {
    Name = "${var.project_name}-private-subnet"
    Tier = "private"
  }
}