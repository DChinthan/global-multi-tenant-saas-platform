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