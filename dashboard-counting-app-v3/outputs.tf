# ─────────────────────────────────────────
# BASTION (public EC2)
# ─────────────────────────────────────────

output "bastion_public_ip" {
  description = "Public IP to SSH into the bastion"
  value       = module.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion inside the VPC"
  value       = module.bastion.private_ip
}

# ─────────────────────────────────────────
# APP SERVER (private EC2)
# ─────────────────────────────────────────

output "app_server_private_ip" {
  description = "Private IP of the app server — only reachable from bastion"
  value       = module.app_server.private_ip
}

# ─────────────────────────────────────────
# NETWORKING
# ─────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "nat_gateway_public_ip" {
  description = "Static public IP the app server uses for outbound traffic"
  value       = module.vpc.nat_public_ips[0]
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnets[0]
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.vpc.private_subnets[0]
}

# ─────────────────────────────────────────
# READY-TO-USE COMMANDS
# ─────────────────────────────────────────

output "ssh_to_bastion" {
  description = "Copy-paste SSH command to reach the bastion"
  value       = "ssh -i ${var.key_name}.pem -A ec2-user@${module.bastion.public_ip}"
}

output "ssh_to_app_server" {
  description = "Run this AFTER SSHing into bastion"
  value       = "ssh ec2-user@${module.app_server.private_ip}"
}

output "dashboard_url" {
  description = "Open this in your browser to see the dashboard"
  value       = "http://${module.bastion.public_ip}:9000"
}
