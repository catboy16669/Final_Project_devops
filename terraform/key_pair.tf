# ── EC2 Key Pair ──────────────────────────────────────────────────
# Uploads your PUBLIC key to AWS so both EC2 instances can be
# accessed with your PRIVATE key (stored in GitHub Secrets).
#
# You generate this key ONCE on your laptop:
#   ssh-keygen -t rsa -b 2048 -f aupp-lms-key -N ""
#   → creates: aupp-lms-key      (private key → GitHub Secret: EC2_SSH_PRIVATE_KEY)
#   → creates: aupp-lms-key.pub  (public key  → GitHub Secret: EC2_SSH_PUBLIC_KEY)
# ─────────────────────────────────────────────────────────────────
resource "aws_key_pair" "aupp_lms" {
  key_name   = "aupp-lms-key"
  public_key = var.ec2_public_key

  tags = {
    Name    = "aupp-lms-key"
    Project = var.project_name
  }

  lifecycle {
    # If key already exists from a previous run, ignore the conflict
    ignore_changes = [public_key]
  }
}
