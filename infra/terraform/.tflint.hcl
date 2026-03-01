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

# 🔧 Phase 0 / Phase 2 scaffolding — allow placeholders
rule "terraform_unused_declarations" {
  enabled = false
}

rule "terraform_required_version" {
  enabled = false
}

rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = true
}