# Step 1 — generate the RSA private key locally in Terraform memory
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Step 2 — upload the PUBLIC half to AWS as a named key pair
resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.project_name}-keypair"
  }
}

# Step 3 — save the PRIVATE half to your local machine as a .pem file
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0600"
}