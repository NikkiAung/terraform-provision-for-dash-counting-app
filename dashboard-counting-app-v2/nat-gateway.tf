# Elastic IP — the static public IP address the NAT gateway uses
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  # EIP must be created after the IGW exists
  # AWS requires an IGW attached to the VPC before allocating EIPs
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway — sits in public subnet, serves the private subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  # NAT Gateway must be created after the IGW
  # Without IGW, the NAT gateway has no path to the internet
  depends_on = [aws_internet_gateway.main]
}