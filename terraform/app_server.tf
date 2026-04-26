# ═══════════════════════════════════════════════════════════════
# APP SERVER
# t2.small — runs 4 containers: website, nginx-exporter,
#            prometheus, grafana
# ═══════════════════════════════════════════════════════════════
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.app_instance_type
  key_name               = aws_key_pair.aupp_lms.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  root_block_device {
    volume_size = 15
    volume_type = "gp2"
  }

  # ── Bootstrap Script ─────────────────────────────────────────
  # Only installs Docker. The actual app containers are deployed
  # by the GitHub Actions pipeline after this EC2 is ready.
  user_data = <<-EOF
    #!/bin/bash
    set -e

    echo "=== Starting App server setup ===" >> /home/ubuntu/setup.log

    # System updates
    apt-get update -y
    apt-get install -y docker.io curl wget

    # Start Docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    # Create monitoring config directory
    mkdir -p /home/ubuntu/monitoring
    chown ubuntu:ubuntu /home/ubuntu/monitoring

    echo "=== App server ready ===" >> /home/ubuntu/setup.log
    echo "=== Docker version: $(docker --version) ===" >> /home/ubuntu/setup.log
  EOF

  tags = {
    Name        = "aupp-app-server"
    Environment = "production"
    Project     = var.project_name
    Role        = "app"
  }
}
