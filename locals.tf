locals {

  project_name = "DP"

  common_tags = {
    Project     = local.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "David"
  }

}