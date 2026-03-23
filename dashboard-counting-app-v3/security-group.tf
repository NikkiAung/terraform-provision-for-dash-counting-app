# ─────────────────────────────────────────
# BASTION SECURITY GROUP (dashboard-service)
# Attached to: public EC2 in us-west-1a
# ─────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = module.vpc.vpc_id # ← only change from before

  # Allow SSH only from your IP
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Allow HTTP on port 9000 from anywhere
  ingress {
    description = "Dashboard service port"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# ─────────────────────────────────────────
# APP SERVER SECURITY GROUP (counting-service)
# Attached to: private EC2 in us-west-1c
# ─────────────────────────────────────────

resource "aws_security_group" "app_server" {
  name        = "${var.project_name}-app-server-sg"
  description = "Security group for private app server"
  vpc_id      = module.vpc.vpc_id # ← only change from before

  # Allow SSH only from bastion security group
  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow port 9001 only from bastion security group
  ingress {
    description     = "Counting service from bastion only"
    from_port       = 9001
    to_port         = 9001
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-server-sg"
  }
}