# ─────────────────────────────────────────
# BASTION (public EC2)
# ─────────────────────────────────────────

output "bastion_public_ip" {
  description = "Public IP to SSH into the bastion"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion inside the VPC"
  value       = aws_instance.bastion.private_ip
}

# ─────────────────────────────────────────
# APP SERVER (private EC2)
# ─────────────────────────────────────────

output "app_server_private_ip" {
  description = "Private IP of the app server — only reachable from bastion"
  value       = aws_instance.app_server.private_ip
}

# ─────────────────────────────────────────
# NETWORKING
# ─────────────────────────────────────────

output "nat_gateway_public_ip" {
  description = "Static public IP the app server uses for outbound traffic"
  value       = aws_eip.nat.public_ip
}

output "vpc_id" {
  description = "VPC ID — useful for adding resources later"
  value       = aws_vpc.main.id
}

# ─────────────────────────────────────────
# READY-TO-USE COMMANDS
# ─────────────────────────────────────────

output "ssh_to_bastion" {
  description = "Copy-paste SSH command to reach the bastion"
  value       = "ssh -i ${var.key_name}.pem -A ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_to_app_server" {
  description = "Run this AFTER SSHing into bastion to reach app server"
  value       = "ssh ec2-user@${aws_instance.app_server.private_ip}"
}

output "dashboard_url" {
  description = "Open this in your browser to see the dashboard"
  value       = "http://${aws_instance.bastion.public_ip}:9000"
}