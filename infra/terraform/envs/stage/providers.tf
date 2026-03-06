############################################
# Default AWS Provider (main region)
############################################
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "global-mt-saas"
      ManagedBy = "terraform"
      Env       = var.environment
    }
  }
}

############################################
# Secondary Provider (required for ACM)
# CloudFront certificates MUST be in us-east-1
############################################
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}