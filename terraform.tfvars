#########################################################
# DP Platform Environment Configuration
#########################################################

aws_region  = "us-east-2"
environment = "dev"

#########################################################
# Networking
#########################################################

vpc_cidr = "10.0.0.0/16"

public_subnets = {
  us-east-2a = "10.0.0.0/20"
  us-east-2b = "10.0.32.0/20"
}

private_subnets = {
  us-east-2a = "10.0.16.0/20"
  us-east-2b = "10.0.48.0/20"
}

admin_ip = "0.0.0.0/0"

#########################################################
# EC2
#########################################################

key_pair_name = "dp-platform-keypair"

# Jenkins Controller and Permanent Build Agent
instance_type = "t3.medium"

# Platform Operations / Artifactory Host
platform_ops_instance_type = "t3.large"

#########################################################
# EKS
#########################################################

enable_eks_runtime = false