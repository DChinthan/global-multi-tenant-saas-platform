variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "role_name" {
  type    = string
  default = "github-actions-oidc-role"
}

variable "allowed_branches" {
  type    = list(string)
  default = ["main", "stage"]
}