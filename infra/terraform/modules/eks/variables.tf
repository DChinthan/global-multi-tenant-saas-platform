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

variable "vpc_id" {
  description = "VPC to place the cluster and node group in (module.vpc.vpc_id)"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private subnets for worker nodes (module.vpc.private_app_subnet_ids)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets, added to the cluster's vpc_config alongside the private ones so the control plane can provision public-facing ENIs if a public endpoint is ever enabled"
  type        = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server endpoint is reachable from the internet. False keeps it VPC-only (recommended outside of demos)."
  type        = bool
  default     = false
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}
