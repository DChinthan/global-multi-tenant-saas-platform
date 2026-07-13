terraform {
  # ==========================================================
  # REMOTE BACKEND DESIGN (NOT ENABLED YET)
  # ==========================================================
  #
  # backend "s3" {
  #   bucket         = "your-org-terraform-state"
  #   key            = "saas-platform/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "your-org-terraform-locks"
  #   encrypt        = true
  # }
  #
  # DO NOT UNCOMMENT until:
  # - S3 bucket exists
  # - DynamoDB lock table exists
  # - Versioning enabled
  # - Encryption enabled
  #
  # ==========================================================

  required_version = ">= 1.6.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # module.monitoring only - see modules/monitoring/versions.tf
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }
}