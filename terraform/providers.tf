terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── S3 Backend: stores terraform state remotely ──────────────────
  # This lets GitHub Actions remember what infrastructure exists
  # between pipeline runs so it doesn't create duplicate EC2 instances.
  #
  # SETUP (one time only):
  #   1. Go to AWS Console → S3 → Create bucket
  #   2. Name: aupp-lms-tfstate-YOUR_NAME  (must be globally unique)
  #   3. Region: us-east-1
  #   4. Block all public access: ON
  #   5. Add bucket name as GitHub Secret: TF_STATE_BUCKET
  #
  # The bucket name is passed in at pipeline runtime via:
  #   terraform init -backend-config="bucket=${TF_STATE_BUCKET}"
  # ─────────────────────────────────────────────────────────────────
  backend "s3" {
    key     = "aupp-lms/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # bucket is passed dynamically via -backend-config in GitHub Actions
  }
}

# ── AWS Provider ──────────────────────────────────────────────────
# Supports AWS Student Lab credentials (includes session token)
provider "aws" {
  region = var.aws_region
}
