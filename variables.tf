#########################################################
# DP Platform Variables
#########################################################

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

#########################################################
# Networking
#########################################################

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

#########################################################
# EC2
#########################################################

variable "key_pair_name" {
  description = "EC2 key pair"
  type        = string
}

variable "instance_type" {
  description = "Default EC2 instance type for DP platform servers"
  type        = string
}

variable "platform_ops_instance_type" {
  description = "EC2 instance type for the DP Platform Operations server"
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