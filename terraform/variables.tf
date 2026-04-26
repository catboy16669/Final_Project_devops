# ── Region ────────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region - us-east-1 is default for AWS Student Lab"
  type        = string
  default     = "us-east-1"
}

# ── SSH Key ───────────────────────────────────────────────────────
# This is the PUBLIC key content (not the private key).
# Generated locally once with: ssh-keygen -t rsa -b 2048 -f aupp-lms-key
# Then stored in GitHub Secret: EC2_SSH_PUBLIC_KEY
variable "ec2_public_key" {
  description = "SSH public key content for EC2 access"
  type        = string
  # Passed in from GitHub Actions via -var flag
}

# ── Instance Types ────────────────────────────────────────────────
variable "app_instance_type" {
  description = "EC2 type for App server (website + Prometheus + Grafana)"
  type        = string
  default     = "t2.small"
  # t2.micro works but t2.small is more stable for running 4 containers
}

# ── Project Tag ───────────────────────────────────────────────────
variable "project_name" {
  description = "Tag applied to all resources"
  type        = string
  default     = "AUPP-LMS"
}
