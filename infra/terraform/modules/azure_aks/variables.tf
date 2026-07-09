variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "kubernetes_version" {
  description = "Leave null to let Azure pick its current default AKS version"
  type        = string
  default     = null
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "storage_account_tier" {
  type    = string
  default = "Standard"
}

variable "storage_replication_type" {
  type    = string
  default = "LRS"
}
