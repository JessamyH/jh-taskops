variable "aws_region" {
  description = "AWS region for regional resources."
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_account_id" {
  description = "AWS account ID Terraform is allowed to manage."
  type        = string
  default     = "956519721376"
}

variable "project_name" {
  description = "Project name used for naming and tagging resources."
  type        = string
  default     = "jh-taskops"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}
