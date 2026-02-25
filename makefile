.PHONY: tf-fmt tf-validate

tf-fmt:
	cd infra/terraform && terraform fmt -recursive

tf-validate:
	cd infra/terraform && terraform init -backend=false && terraform validate