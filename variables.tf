variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  description = "Deployment Environment"
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block for the DP VPC"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets"
  type        = map(string)
}

variable "private_subnets" {
  description = "Private subnets"
  type        = map(string)
}
variable "admin_ip" {
  description = "Public IP allowed to administer the platform"
  type        = string
}
variable "key_pair_name" {
  description = "EC2 Key Pair"
  type        = string
}

variable "instance_type" {
  description = "Default EC2 instance type"
  type        = string
}

#########################################################
# Expensive EKS Runtime Toggle
#########################################################

variable "enable_eks_runtime" {
  description = "Create billable EKS runtime resources such as NAT Gateway, EKS cluster, and worker nodes"
  type        = bool
  default     = false
}