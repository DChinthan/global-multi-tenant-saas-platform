variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" { type = string }
variable "environment" { type = string }

# COST-SAFETY TOGGLES
variable "enable_nat" {
  type    = bool
  default = false
}
variable "enable_rds" {
  type    = bool
  default = false
}
variable "enable_opensearch" {
  type    = bool
  default = false
}
variable "enable_kinesis" {
  type    = bool
  default = false
}

# Example sizing knobs (keep tiny in dev)
variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "opensearch_instance_type" {
  type    = string
  default = "t3.small.search"
}