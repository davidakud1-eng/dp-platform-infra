#########################################################
# DP EKS Cluster
# Ephemeral - controlled by enable_eks_runtime
#########################################################

resource "aws_eks_cluster" "dp_cluster" {

  count = var.enable_eks_runtime ? 1 : 0

  name     = "dp-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  version = "1.34"

  #######################################################
  # EKS Networking
  #######################################################

  vpc_config {
    subnet_ids = [
      aws_subnet.private["us-east-2a"].id,
      aws_subnet.private["us-east-2b"].id
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  #######################################################
  # EKS Authentication
  #######################################################

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  #######################################################
  # Dependencies
  #######################################################

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  #######################################################
  # Tags
  #######################################################

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-eks-cluster"
      Component = "Kubernetes"
      Role      = "EKS Control Plane"
    }
  )
}

#########################################################
# DP EKS Managed Node Group
# Ephemeral - controlled by enable_eks_runtime
#########################################################

resource "aws_eks_node_group" "dp_nodes" {

  count = var.enable_eks_runtime ? 1 : 0

  cluster_name    = aws_eks_cluster.dp_cluster[0].name
  node_group_name = "dp-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  #######################################################
  # Worker Node Networking
  #######################################################

  subnet_ids = [
    aws_subnet.private["us-east-2a"].id,
    aws_subnet.private["us-east-2b"].id
  ]

  #######################################################
  # Worker Node Compute
  #######################################################

  instance_types = [
    "t3.medium"
  ]

  capacity_type = "ON_DEMAND"

  #######################################################
  # Node Group Scaling
  #######################################################

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }

  #######################################################
  # Rolling Update Behaviour
  #######################################################

  update_config {
    max_unavailable = 1
  }

  #######################################################
  # Dependencies
  #######################################################

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_ecr_pull_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_route_table_association.private_2a,
    aws_route_table_association.private_2b
  ]

  #######################################################
  # Tags
  #######################################################

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-eks-node-group"
      Component = "Kubernetes"
      Role      = "EKS Worker Nodes"
    }
  )
}

#########################################################
# Platform Ops EKS Access Entry
# Allows dp-platform-ops-role to authenticate to EKS
#########################################################

resource "aws_eks_access_entry" "platform_ops" {

  count = var.enable_eks_runtime ? 1 : 0

  cluster_name  = aws_eks_cluster.dp_cluster[0].name
  principal_arn = aws_iam_role.platform_ops_role.arn
  type          = "STANDARD"

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-platform-ops-access"
      Component = "Kubernetes"
      Role      = "Platform Operations Access"
    }
  )
}

#########################################################
# Platform Ops EKS Administrative Access
#########################################################

resource "aws_eks_access_policy_association" "platform_ops_admin" {

  count = var.enable_eks_runtime ? 1 : 0

  cluster_name  = aws_eks_cluster.dp_cluster[0].name
  principal_arn = aws_iam_role.platform_ops_role.arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.platform_ops
  ]
}

###################################################
# Platform Ops Access to EKS Private API
###################################################

resource "aws_vpc_security_group_ingress_rule" "platform_ops_to_eks_api" {
  count = var.enable_eks_runtime ? 1 : 0

  security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id

  referenced_security_group_id = aws_security_group.platform_ops.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow Platform Ops to access EKS private API"
}

#########################################################
# EKS Pod Identity Agent
# Provides AWS credentials to Kubernetes workloads
#########################################################

resource "aws_eks_addon" "pod_identity_agent" {

  count = var.enable_eks_runtime ? 1 : 0

  cluster_name = aws_eks_cluster.dp_cluster[0].name
  addon_name   = "eks-pod-identity-agent"

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-eks-pod-identity-agent"
      Component = "Kubernetes"
      Role      = "Pod AWS Identity"
    }
  )

  depends_on = [
    aws_eks_node_group.dp_nodes
  ]
}