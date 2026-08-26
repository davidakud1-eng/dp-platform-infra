#########################################################
# DP Platform Security Groups
# Project 1 - Traditional DevSecOps Platform
#########################################################


#########################################################
# Jenkins Controller Security Group
#########################################################

resource "aws_security_group" "jenkins" {

  name        = "dp-jenkins-sg"
  description = "Security Group for DP Jenkins Controller"
  vpc_id      = aws_vpc.dp_vpc.id

  #######################################################
  # SSH - Administrator Workstation
  #######################################################

  ingress {
    description = "SSH from Administrator Workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  #######################################################
  # SSH - Platform Operations Server (Ansible)
  #######################################################

  ingress {
    description     = "SSH from Platform Operations Server"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.platform_ops.id]
  }

  #######################################################
  # Jenkins Web UI
  #######################################################

  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  #######################################################
  # Outbound
  #######################################################

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "dp-jenkins-sg"
    }
  )
}


#########################################################
# Permanent Jenkins Build Agent Security Group
#########################################################

resource "aws_security_group" "build_agent" {

  name        = "dp-build-agent-sg"
  description = "Security Group for DP Permanent Jenkins Build Agent"
  vpc_id      = aws_vpc.dp_vpc.id

  #######################################################
  # SSH - Administrator Workstation
  #######################################################

  ingress {
    description = "SSH from Administrator Workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  #######################################################
  # SSH - Platform Operations Server (Ansible)
  #######################################################

  ingress {
    description     = "SSH from Platform Operations Server"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.platform_ops.id]
  }

  #######################################################
  # Jenkins Inbound Agent
  #######################################################

  ingress {
    description     = "Jenkins Inbound Agent Communication"
    from_port       = 50000
    to_port         = 50000
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins.id]
  }

  #######################################################
  # Outbound
  #######################################################

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "dp-build-agent-sg"
    }
  )
}


#########################################################
# Platform Operations Server Security Group
#########################################################

resource "aws_security_group" "platform_ops" {

  name        = "dp-platform-ops-sg"
  description = "Security Group for DP Platform Operations Server"
  vpc_id      = aws_vpc.dp_vpc.id

  #######################################################
  # SSH - Administrator Workstation
  #######################################################

  ingress {
    description = "SSH from Administrator Workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  #######################################################
  # JFrog Artifactory Web UI - Administrator
  #######################################################

  ingress {
    description = "Artifactory Web UI from Administrator Workstation"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  #######################################################
  # Outbound
  #######################################################

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "dp-platform-ops-sg"
    }
  )
}


#########################################################
# JFrog Artifactory Internal Access
#
# Cross-security-group rules are defined separately to
# prevent circular dependencies between the Jenkins,
# Build Agent, and Platform Operations security groups.
#########################################################

#########################################################
# JFrog Artifactory - Jenkins Controller
#########################################################

resource "aws_security_group_rule" "artifactory_from_jenkins" {

  type        = "ingress"
  description = "Artifactory from Jenkins Controller"
  from_port   = 8082
  to_port     = 8082
  protocol    = "tcp"

  security_group_id        = aws_security_group.platform_ops.id
  source_security_group_id = aws_security_group.jenkins.id
}


#########################################################
# JFrog Artifactory - Build Agent
#########################################################

resource "aws_security_group_rule" "artifactory_from_build_agent" {

  type        = "ingress"
  description = "Artifactory from Build Agent"
  from_port   = 8082
  to_port     = 8082
  protocol    = "tcp"

  security_group_id        = aws_security_group.platform_ops.id
  source_security_group_id = aws_security_group.build_agent.id
}





#########################################################
# EKS Prometheus Monitoring Access
#
# Allows Prometheus workloads running in EKS to scrape
# metrics from the DP platform EC2 instances.
#########################################################


#########################################################
# Node Exporter - Jenkins Controller
#########################################################

resource "aws_security_group_rule" "node_exporter_from_eks_to_jenkins" {

  count = var.enable_eks_runtime ? 1 : 0

  type        = "ingress"
  description = "Node Exporter from EKS Prometheus"
  from_port   = 9100
  to_port     = 9100
  protocol    = "tcp"

  security_group_id = aws_security_group.jenkins.id

  source_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}


#########################################################
# Node Exporter - Build Agent
#########################################################

resource "aws_security_group_rule" "node_exporter_from_eks_to_build_agent" {

  count = var.enable_eks_runtime ? 1 : 0

  type        = "ingress"
  description = "Node Exporter from EKS Prometheus"
  from_port   = 9100
  to_port     = 9100
  protocol    = "tcp"

  security_group_id = aws_security_group.build_agent.id

  source_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}


#########################################################
# Node Exporter - Platform Operations
#########################################################

resource "aws_security_group_rule" "node_exporter_from_eks_to_platform_ops" {

  count = var.enable_eks_runtime ? 1 : 0

  type        = "ingress"
  description = "Node Exporter from EKS Prometheus"
  from_port   = 9100
  to_port     = 9100
  protocol    = "tcp"

  security_group_id = aws_security_group.platform_ops.id

  source_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}


#########################################################
# Jenkins Prometheus Plugin - EKS Prometheus
#########################################################

resource "aws_security_group_rule" "jenkins_metrics_from_eks" {

  count = var.enable_eks_runtime ? 1 : 0

  type        = "ingress"
  description = "Jenkins Prometheus metrics from EKS"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"

  security_group_id = aws_security_group.jenkins.id

  source_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}