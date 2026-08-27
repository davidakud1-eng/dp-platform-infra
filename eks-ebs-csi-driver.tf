#########################################################
# DP Amazon EBS CSI Driver
#
# Provides dynamic Amazon EBS volume provisioning
# for persistent Kubernetes workloads in DP EKS.
#
# The EBS CSI controller receives AWS permissions
# through EKS Pod Identity.
#########################################################


#########################################################
# Amazon EBS CSI Driver IAM Role
#
# This role is assumed by the EBS CSI controller
# through EKS Pod Identity.
#
# IMPORTANT:
# EBS permissions are NOT attached directly to the
# EKS worker node role.
#########################################################

resource "aws_iam_role" "ebs_csi_driver" {

  name = "dp-ebs-csi-driver-role"

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
      Name      = "dp-ebs-csi-driver-role"
      Component = "Kubernetes"
      Role      = "EBS CSI Driver"
    }
  )
}


#########################################################
# Attach AWS Managed EBS CSI Driver Policy
#
# AWS maintains the permissions required by the
# EBS CSI driver in AmazonEBSCSIDriverPolicy.
#########################################################

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {

  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


#########################################################
# Amazon EBS CSI Driver EKS Add-on
#
# The Pod Identity association is managed as part of
# the EKS add-on itself.
#
# Association:
#
# aws-ebs-csi-driver
#       |
#       v
# ebs-csi-controller-sa
#       |
#       v
# dp-ebs-csi-driver-role
#       |
#       v
# AmazonEBSCSIDriverPolicy
#########################################################

resource "aws_eks_addon" "ebs_csi_driver" {

  count = var.enable_eks_runtime ? 1 : 0

  cluster_name = aws_eks_cluster.dp_cluster[0].name
  addon_name   = "aws-ebs-csi-driver"

  #######################################################
  # EKS Pod Identity
  #######################################################

  pod_identity_association {
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi_driver.arn
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-aws-ebs-csi-driver"
      Component = "Kubernetes"
      Role      = "Persistent Storage"
    }
  )

  depends_on = [
    aws_eks_node_group.dp_nodes,
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}