############################################
# Observability Module
#
# Implements production observability stack
# for the SaaS platform including:
#
# - CloudWatch Logs
# - Metrics & Alarms
# - CloudWatch Dashboard
# - X-Ray tracing permissions
# - Centralized audit logging
# - CloudTrail + Athena
#
############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}