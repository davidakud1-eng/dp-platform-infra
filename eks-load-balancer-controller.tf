#########################################################
# DP AWS Load Balancer Controller
#
# Provides AWS IAM permissions to the
# aws-load-balancer-controller Kubernetes workload
# using EKS Pod Identity.
#########################################################


#########################################################
# AWS Load Balancer Controller IAM Role
#
# This role is assumed by the controller workload
# through EKS Pod Identity.
#
# IMPORTANT:
# These permissions are NOT attached to the EKS
# worker node role.
#########################################################

resource "aws_iam_role" "aws_load_balancer_controller" {

  name = "dp-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "pods.eks.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-aws-load-balancer-controller-role"
      Component = "Kubernetes"
      Role      = "AWS Load Balancer Controller"
    }
  )
}


#########################################################
# AWS Load Balancer Controller IAM Policy
#
# The policy document is stored separately under:
#
# iam/aws-load-balancer-controller-policy.json
#
# The JSON policy must match the AWS Load Balancer
# Controller version deployed through Helm.
#########################################################

resource "aws_iam_policy" "aws_load_balancer_controller" {

  name        = "dp-aws-load-balancer-controller-policy"
  description = "IAM permissions for the DP AWS Load Balancer Controller"

  policy = file(
    "${path.module}/iam/aws-load-balancer-controller-policy.json"
  )

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-aws-load-balancer-controller-policy"
      Component = "Kubernetes"
      Role      = "AWS Load Balancer Controller Permissions"
    }
  )
}


#########################################################
# Attach Controller IAM Policy to Controller IAM Role
#########################################################

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {

  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}


#########################################################
# AWS Load Balancer Controller
# EKS Pod Identity Association
#
# Association:
#
# dp-eks-cluster
#       |
#       v
# kube-system namespace
#       |
#       v
# aws-load-balancer-controller ServiceAccount
#       |
#       v
# dp-aws-load-balancer-controller-role
#########################################################

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {

  count = var.enable_eks_runtime ? 1 : 0

  cluster_name = aws_eks_cluster.dp_cluster[0].name

  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"

  role_arn = aws_iam_role.aws_load_balancer_controller.arn

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-aws-load-balancer-controller"
      Component = "Kubernetes"
      Role      = "AWS Load Balancer Controller Pod Identity"
    }
  )

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}