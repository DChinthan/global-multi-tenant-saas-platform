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

# 🔧 Phase 2 scaffolding relaxations

# We haven't finalized module interfaces yet
rule "terraform_unused_declarations" {
  enabled = false
}

# We don't want module-structure policing while building
rule "terraform_standard_module_structure" {
  enabled = false
}

# globals folder isn't a real root yet
rule "terraform_required_version" {
  enabled = false
}

# Documentation rules can wait until interfaces stabilize
rule "terraform_documented_variables" {
  enabled = false
}

rule "terraform_documented_outputs" {
  enabled = false
}

# Provider noise during scaffolding
rule "terraform_unused_required_providers" {
  enabled = false
}

# ✅ Keep important structural check
rule "terraform_required_providers" {
  enabled = true
}