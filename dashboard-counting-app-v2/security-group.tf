# ─────────────────────────────────────────
# BASTION SECURITY GROUP (dashboard-service)
# Attached to: public EC2 in us-west-1a
# ─────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  # Allow SSH only from your IP
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Allow HTTP on port 9000 from anywhere
  # This is how users reach the dashboard service
  ingress {
    description = "Dashboard service port"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  # Bastion needs to SSH into app server + reach internet
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
# Attached to: private EC2 in us-west-1b
# ─────────────────────────────────────────

resource "aws_security_group" "app_server" {
  name        = "${var.project_name}-app-server-sg"
  description = "Security group for private app server"
  vpc_id      = aws_vpc.main.id

  # Allow SSH only from bastion security group
  # NOT from a CIDR — from the SG itself
  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow port 9001 only from bastion security group
  # Counting service port, only bastion can call it
  ingress {
    description     = "Counting service from bastion only"
    from_port       = 9001
    to_port         = 9001
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow all outbound
  # App server needs NAT gateway to reach internet for updates
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