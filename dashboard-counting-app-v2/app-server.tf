resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.app_server.id]
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y curl wget unzip

    cd /home/ec2-user

    # Download counting service
    wget https://github.com/hashicorp/demo-consul-101/releases/download/0.0.3.1/counting-service_linux_amd64.zip
    unzip counting-service_linux_amd64.zip
    chmod +x counting-service_linux_amd64

    # Run counting service on port 9001
    nohup env PORT=9001 ./counting-service_linux_amd64 > /home/ec2-user/counting-service.log 2>&1 &
  EOF

  tags = {
    Name = "${var.project_name}-app-server"
    Role = "app-server"
  }
}