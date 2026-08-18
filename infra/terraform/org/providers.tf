############################################
# This root config must be applied with credentials for the AWS
# Organizations MANAGEMENT account - a different account context than
# infra/terraform/envs/{dev,stage,prod}, which are workload environments
# that live *inside* member accounts this config can create.
#
# Region is arbitrary for Organizations API calls (it's a global service),
# but pinned for consistency with the rest of the repo.
############################################

provider "aws" {
  region = "us-east-1"
}
