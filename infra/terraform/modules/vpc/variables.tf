variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "enable_nat" {
  type    = bool
  default = false
}