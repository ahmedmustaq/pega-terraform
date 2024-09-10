variable "project_id" {
  description = "The project ID where the aws cluster will be created"
  default     = "pegajenkins"
}

variable "region" {
  description = "The region where the aws cluster will be created"
  type = string
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "The name of the aws cluster"
  default     = "pega-gcp-cluster"
}

variable "instance_type" {
  description = "The machine type to use for nodes"
  default     = "t3.medium"
}

variable "node_count" {
  description = "The number of nodes in the node pool"
  default     = 3
}

