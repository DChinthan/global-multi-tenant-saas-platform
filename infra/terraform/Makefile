# Root Terraform directory
TF_ROOT := $(CURDIR)

# Default environment
ENV ?= dev
TF_ENV_DIR := $(TF_ROOT)/envs/$(ENV)

.PHONY: tf-fmt tf-fmt-check tf-init tf-validate tf-plan lint sec

# Format all Terraform code
tf-fmt:
	cd $(TF_ROOT) && terraform fmt -recursive

# Check formatting (same as CI)
tf-fmt-check:
	cd $(TF_ROOT) && terraform fmt -check -recursive

# Initialize selected environment
tf-init:
	terraform -chdir=$(TF_ENV_DIR) init -backend=false

# Validate selected environment
tf-validate:
	terraform -chdir=$(TF_ENV_DIR) init -backend=false
	terraform -chdir=$(TF_ENV_DIR) validate

# Plan selected environment
tf-plan:
	terraform -chdir=$(TF_ENV_DIR) init -backend=false
	terraform -chdir=$(TF_ENV_DIR) plan

# Lint entire Terraform repo
lint:
	cd $(TF_ROOT) && tflint --init
	cd $(TF_ROOT) && tflint --recursive

# Security scan entire Terraform repo
sec:
	cd $(TF_ROOT) && tfsec .