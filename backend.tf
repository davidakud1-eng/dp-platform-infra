#########################################################
# Terraform Remote Backend
#########################################################

terraform {
  backend "s3" {
    bucket       = "dp-terraform-state-686953641182"
    key          = "dp-platform/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}