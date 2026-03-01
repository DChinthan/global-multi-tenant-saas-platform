# Default environment
ENV ?= dev
TF_DIR = envs/$(ENV)

.PHONY: tf-fmt tf-init tf-validate tf-plan lint sec

# Format all Terraform code
tf-fmt:
	terraform fmt -recursive

# Initialize selected environment
tf-init:
	cd $(TF_DIR) && terraform init -backend=false

# Validate selected environment
tf-validate:
	cd $(TF_DIR) && terraform init -backend=false && terraform validate

# Plan selected environment
tf-plan:
	cd $(TF_DIR) && terraform init -backend=false && terraform plan

# Lint entire Terraform repo
lint:
	tflint --init
	tflint --recursive

# Security scan entire Terraform repo
sec:
	tfsec .