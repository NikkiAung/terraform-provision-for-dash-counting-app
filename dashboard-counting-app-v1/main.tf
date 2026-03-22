module "dashboard_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name           = var.dashboard_name
  cidr           = var.dashboard_cidr
  public_subnets = var.public_subnets_for_dashboard
  azs            = var.dashboard-app-azs
}

module "counting_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name                = var.counting_name
  cidr                = var.counting_cidr
  public_subnets      = var.public_subnets_for_counting
  azs                 = var.counting-app-azs
  private_subnets     = var.private_subnets_for_counting
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  tags                = var.tags
  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags
}