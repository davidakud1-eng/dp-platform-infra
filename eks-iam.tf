#########################################################
# DP EKS IAM Roles
#########################################################

#########################################################
# EKS Cluster Role
#########################################################

resource "aws_iam_role" "eks_cluster_role" {

  name = "dp-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-eks-cluster-role"
      Component = "IAM"
      Role      = "EKS Cluster"
    }
  )
}

#########################################################
# EKS Cluster Policy
#########################################################

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {

  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


#########################################################
# EKS Worker Node Role
#########################################################

resource "aws_iam_role" "eks_node_role" {

  name = "dp-eks-node-role"

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
      Name      = "dp-eks-node-role"
      Component = "IAM"
      Role      = "EKS Worker Nodes"
    }
  )
}

#########################################################
# EKS Worker Node Policy
#########################################################

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {

  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

#########################################################
# ECR Pull Policy
#########################################################

resource "aws_iam_role_policy_attachment" "eks_ecr_pull_policy" {

  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

#########################################################
# EKS CNI Policy
#########################################################

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {

  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}