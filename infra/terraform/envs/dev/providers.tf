############################################
# Default AWS Provider (main region)
############################################
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "global-mt-saas"
      ManagedBy = "terraform"
      Env       = var.env
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

############################################
# Kubernetes / Helm providers (module.monitoring)
#
# Only ever meaningful when enable_eks = true. The `exec` block below calls
# `aws eks get-token` at plan/apply time instead of a static bearer token -
# same IAM-based, short-lived-credential pattern as the GitHub Actions OIDC
# role used elsewhere in this repo (see modules/ci_cd_oidc), just for a
# human/CI caller talking to the cluster instead of AWS APIs directly.
#
# The `var.enable_eks ? ... : "placeholder"` guards exist because these
# provider blocks are evaluated even when enable_eks = false and
# module.eks has zero instances - without a fallback, referencing
# module.eks[0] would fail during plan on a cluster-less apply.
############################################
provider "kubernetes" {
  host                   = var.enable_eks ? module.eks[0].cluster_endpoint : "https://placeholder.invalid"
  cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_name : "placeholder"]
  }
}

provider "helm" {
  kubernetes {
    host                   = var.enable_eks ? module.eks[0].cluster_endpoint : "https://placeholder.invalid"
    cluster_ca_certificate = var.enable_eks ? base64decode(module.eks[0].cluster_certificate_authority_data) : null

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.enable_eks ? module.eks[0].cluster_name : "placeholder"]
    }
  }
}