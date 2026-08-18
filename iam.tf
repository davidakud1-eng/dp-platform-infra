#########################################################
# DP Platform IAM Role
#########################################################

resource "aws_iam_role" "platform_role" {

  name = "dp-platform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "dp-platform-role"
    }
  )
}

#########################################################
# Instance Profile
#########################################################

resource "aws_iam_instance_profile" "platform_profile" {

  name = "dp-platform-instance-profile"
  role = aws_iam_role.platform_role.name
}

#########################################################
# SSM Access
#########################################################

resource "aws_iam_role_policy_attachment" "ssm" {

  role       = aws_iam_role.platform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#########################################################
# EC2 Read-Only Access
#########################################################

resource "aws_iam_role_policy_attachment" "ec2_readonly" {

  role       = aws_iam_role.platform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}


#########################################################################
#########################################################################
#########################################################################


#########################################################
# DP Platform Operations IAM Role
# Dedicated Terraform / EKS Execution Role
#########################################################

resource "aws_iam_role" "platform_ops_role" {

  name = "dp-platform-ops-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-platform-ops-role"
      Component = "IAM"
      Role      = "Platform Operations"
    }
  )
}

#########################################################
# Platform Operations Instance Profile
#########################################################

resource "aws_iam_instance_profile" "platform_ops_profile" {

  name = "dp-platform-ops-instance-profile"
  role = aws_iam_role.platform_ops_role.name
}

#########################################################
# Platform Operations - SSM Access
#########################################################

resource "aws_iam_role_policy_attachment" "platform_ops_ssm" {

  role       = aws_iam_role.platform_ops_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#########################################################
# Platform Operations - EC2 Read-Only Access
#########################################################

resource "aws_iam_role_policy_attachment" "platform_ops_ec2_readonly" {

  role       = aws_iam_role.platform_ops_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

#########################################################
# DP Platform Operations - Terraform Execution Policy
#########################################################

resource "aws_iam_policy" "platform_ops_terraform" {

  name        = "dp-platform-ops-terraform-policy"
  description = "Allows DP Platform Operations to manage DP infrastructure using Terraform"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      ###################################################
      # 1. EC2 / VPC Infrastructure Management
      ###################################################
      {
        Sid    = "ManageEC2AndNetworking"
        Effect = "Allow"

        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",

          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",

          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",

          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",

          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",

          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",

          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateRoute",
          "ec2:ReplaceRoute",
          "ec2:DeleteRoute",

          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",

          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]

        Resource = "*"
      },

      ###################################################
      # 2. EKS Infrastructure Management
      ###################################################
      {
        Sid    = "ManageEKS"
        Effect = "Allow"

        Action = [
          "eks:CreateCluster",
          "eks:DescribeCluster",
          "eks:UpdateClusterConfig",
          "eks:UpdateClusterVersion",
          "eks:DeleteCluster",
          "eks:ListClusters",
          "eks:TagResource",
          "eks:UntagResource",

          "eks:CreateNodegroup",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupConfig",
          "eks:UpdateNodegroupVersion",
          "eks:DeleteNodegroup",
          "eks:ListNodegroups",

          "eks:CreateAddon",
          "eks:DescribeAddon",
          "eks:UpdateAddon",
          "eks:DeleteAddon",
          "eks:ListAddons",
          "eks:DescribeAddonVersions",

          "eks:CreateAccessEntry",
          "eks:DescribeAccessEntry",
          "eks:UpdateAccessEntry",
          "eks:DeleteAccessEntry",
          "eks:ListAccessEntries",

          "eks:AssociateAccessPolicy",
          "eks:DisassociateAccessPolicy",
          "eks:ListAssociatedAccessPolicies"
        ]

        Resource = "*"
      },

      ###################################################
      # 3. Manage DP EKS IAM Roles
      ###################################################
      {
        Sid    = "ManageDPEKSRoles"
        Effect = "Allow"

        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",

          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",

          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies"
        ]

        Resource = [
          "arn:aws:iam::*:role/dp-eks-cluster-role",
          "arn:aws:iam::*:role/dp-eks-node-role"
        ]
      },

      ###################################################
      # 4. Read IAM Resources for Terraform State Refresh
      ###################################################
      {
        Sid    = "ReadDPIAMResources"
        Effect = "Allow"

        Action = [
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetInstanceProfile",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListInstanceProfilesForRole"
        ]

        Resource = "*"
      },

      ###################################################
      # 5. Pass DP EKS Roles to AWS Services
      ###################################################
      {
        Sid    = "PassDPEKSRoles"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = [
          "arn:aws:iam::*:role/dp-eks-cluster-role",
          "arn:aws:iam::*:role/dp-eks-node-role"
        ]

        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "eks.amazonaws.com",
              "ec2.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-platform-ops-terraform-policy"
      Component = "IAM"
      Role      = "Terraform Execution"
    }
  )
}

#########################################################
# Attach Terraform Execution Policy to Platform Ops
#########################################################

resource "aws_iam_role_policy_attachment" "platform_ops_terraform" {

  role       = aws_iam_role.platform_ops_role.name
  policy_arn = aws_iam_policy.platform_ops_terraform.arn
}


#########################################################
# DP Platform Ops - Terraform Remote State Policy
#########################################################

resource "aws_iam_policy" "platform_ops_terraform_state" {

  name        = "dp-platform-ops-terraform-state-policy"
  description = "Allows DP Platform Operations to access the Terraform S3 remote backend"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      ###################################################
      # List Terraform State Bucket
      ###################################################
      {
        Sid    = "ListTerraformStateBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::dp-terraform-state-686953641182"
      },

      ###################################################
      # Read / Write Terraform State and Lock Objects
      ###################################################
      {
        Sid    = "ManageTerraformStateObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "arn:aws:s3:::dp-terraform-state-686953641182/dp-platform/*"
        ]
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-platform-ops-terraform-state-policy"
      Component = "IAM"
      Role      = "Terraform Remote State"
    }
  )
}

#########################################################
# Attach Terraform State Policy to Platform Ops
#########################################################

resource "aws_iam_role_policy_attachment" "platform_ops_terraform_state" {

  role       = aws_iam_role.platform_ops_role.name
  policy_arn = aws_iam_policy.platform_ops_terraform_state.arn
}