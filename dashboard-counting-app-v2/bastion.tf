resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  depends_on = [aws_instance.app_server]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y curl wget unzip

    # Enable SSH agent forwarding
    echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config
    systemctl restart sshd

    cd /home/ec2-user

    # Download dashboard service
    wget https://github.com/hashicorp/demo-consul-101/releases/download/0.0.3.1/dashboard-service_linux_amd64.zip
    unzip dashboard-service_linux_amd64.zip
    chmod +x dashboard-service_linux_amd64

    # Run dashboard on port 9000 pointing at counting service on app server
    nohup env PORT=9000 COUNTING_SERVICE_URL="http://${aws_instance.app_server.private_ip}:9001" ./dashboard-service_linux_amd64 > /home/ec2-user/dashboard-service.log 2>&1 &
  EOF

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  }
}