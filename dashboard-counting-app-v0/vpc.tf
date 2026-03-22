resource "aws_vpc" "hellocloud" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.prefix}-vpc-${var.region}"
    environment = "${var.environment}"
  }
}
