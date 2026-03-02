############################################
# Terraform Makefile (Root Level)
############################################

# Default environment (can override: make tf-plan ENV=stage)
ENV ?= dev

# Base Terraform directory
TF_BASE_DIR = infra/terraform
TF_ENV_DIR  = $(TF_BASE_DIR)/envs/$(ENV)

.PHONY: tf-fmt tf-init tf-validate tf-plan tf-apply tf-destroy lint sec

############################################
# Format all Terraform code
############################################
tf-fmt:
	terraform -chdir=$(TF_BASE_DIR) fmt -recursive

############################################
# Initialize selected environment
############################################
tf-init:
	terraform -chdir=$(TF_ENV_DIR) init

############################################
# Validate selected environment
############################################
tf-validate:
	terraform -chdir=$(TF_ENV_DIR) validate

############################################
# Plan selected environment
############################################
tf-plan:
	terraform -chdir=$(TF_ENV_DIR) plan

############################################
# Apply selected environment
############################################
tf-apply:
	terraform -chdir=$(TF_ENV_DIR) apply

############################################
# Destroy selected environment
############################################
tf-destroy:
	terraform -chdir=$(TF_ENV_DIR) destroy

############################################
# Lint entire Terraform repo
############################################
lint:
	tflint --init
	tflint --recursive $(TF_BASE_DIR)

############################################
# Security scan entire Terraform repo
############################################
sec:
	tfsec $(TF_BASE_DIR)