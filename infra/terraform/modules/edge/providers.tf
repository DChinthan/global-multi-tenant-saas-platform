# This module needs a us-east-1 provider for ACM (CloudFront requirement).
# The root module must pass provider aliases:
# providers = { aws = aws, aws.us_east_1 = aws.us_east_1 }

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}