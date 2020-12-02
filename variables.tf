variable "region" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "The name for the cluster created."
}

variable "aws_access_key_id" {
  type        = string
  description = "An aws key id for retrieving the user-data script from the S3 bucket"
}

variable "aws_secret_access_key" {
  type        = string
  description = "An aws secret for retrieving the user-data script from the S3 bucket"
}

variable "aws_s3_bucket" {
  type        = string
  description = "See usage for explanation"
}

variable "aws_user_data_script" {
  type        = string
  description = "The script which should be executed"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.18"
  description = "Desired Kubernetes master version. If you do not specify a value, 1.18 will be used."
}

variable "instance_type" {
  type        = string
  description = "The instance type of the created EC2 instances"
}

variable "volume_size" {
  type        = number
  description = "The volume size of the root device on the EC2 instances"
}

variable "key_pair_name" {
  type        = string
  description = "The key pair associated to the launch config"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
