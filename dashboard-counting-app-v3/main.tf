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

# ─────────────────────────────────────────
# BASTION EC2 MODULE
# Replaces: bastion.tf
# Public subnet, runs dashboard-service
# ─────────────────────────────────────────

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${var.project_name}-bastion"

  # ── AMI + instance type ───────────────
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  # ── Networking ────────────────────────
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  # ── SSH key ───────────────────────────
  key_name = aws_key_pair.main.key_name

  # ── Startup script ────────────────────
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y curl wget unzip

    # Enable SSH agent forwarding
    echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config
    systemctl restart sshd

    cd /home/ec2-user

    # Download dashboard service
    wget -q https://github.com/hashicorp/demo-consul-101/releases/download/0.0.3.1/dashboard-service_linux_amd64.zip

    if [ ! -f dashboard-service_linux_amd64.zip ]; then
      echo "ERROR: Failed to download dashboard-service" >> /home/ec2-user/dashboard-service.log
      exit 1
    fi

    unzip dashboard-service_linux_amd64.zip
    chmod +x dashboard-service_linux_amd64

    # Point dashboard at counting service on app server private IP
    nohup env PORT=9000 COUNTING_SERVICE_URL="http://${module.app_server.private_ip}:9001" \
      ./dashboard-service_linux_amd64 > /home/ec2-user/dashboard-service.log 2>&1 &

    echo "dashboard-service started with PID $!" >> /home/ec2-user/dashboard-service.log
  EOF

  # Wait for app_server to exist so its private IP is known
  depends_on = [module.app_server]

  tags = {
    Name    = "${var.project_name}-bastion"
    Role    = "bastion"
    Project = var.project_name
  }
}


# ─────────────────────────────────────────
# APP SERVER EC2 MODULE
# Replaces: app-server.tf
# Private subnet, runs counting-service
# ─────────────────────────────────────────

module "app_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${var.project_name}-app-server"

  # ── AMI + instance type ───────────────
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  # ── Networking ────────────────────────
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.app_server.id]
  associate_public_ip_address = false

  # ── SSH key ───────────────────────────
  key_name = aws_key_pair.main.key_name

  # ── Startup script ────────────────────
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y curl wget unzip

    cd /home/ec2-user

    # Download counting service
    wget -q https://github.com/hashicorp/demo-consul-101/releases/download/0.0.3.1/counting-service_linux_amd64.zip

    if [ ! -f counting-service_linux_amd64.zip ]; then
      echo "ERROR: Failed to download counting-service" >> /home/ec2-user/counting-service.log
      exit 1
    fi

    unzip counting-service_linux_amd64.zip
    chmod +x counting-service_linux_amd64

    nohup env PORT=9001 ./counting-service_linux_amd64 > /home/ec2-user/counting-service.log 2>&1 &

    echo "counting-service started with PID $!" >> /home/ec2-user/counting-service.log
  EOF

  tags = {
    Name    = "${var.project_name}-app-server"
    Role    = "app-server"
    Project = var.project_name
  }
}