# ── Auto-find latest Ubuntu 22.04 AMI ────────────────────────────
# This always finds the correct AMI for whatever region you use.
# No need to hardcode AMI IDs (which differ per region).
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical (Ubuntu official)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ── Get default VPC ───────────────────────────────────────────────
# Uses the default VPC that exists in every AWS account.
# No need to create a custom VPC for this project.
data "aws_vpc" "default" {
  default = true
}
