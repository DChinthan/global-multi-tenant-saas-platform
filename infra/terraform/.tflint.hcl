plugin "aws" {
  enabled = true
  version = "0.35.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  version = "0.14.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

config {
  format           = "compact"
  call_module_type = "all"
}

# Disable documentation noise during scaffolding
rule "terraform_documented_variables" { enabled = false }
rule "terraform_documented_outputs" { enabled = false }

# Disable provider noise during design phase
rule "terraform_unused_required_providers" { enabled = false }

# Keep important structural checks
rule "terraform_required_providers" { enabled = true }