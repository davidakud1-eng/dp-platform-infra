#########################################################
# DP Platform Security Groups
# Project 1 - Traditional DevSecOps Platform
#########################################################


#########################################################
# Security Groups
#
# Security groups define the network boundaries only.
# All ingress and egress rules are managed separately
# using dedicated VPC security group rule resources.
#########################################################


#########################################################
# Jenkins Controller Security Group
#########################################################

resource "aws_security_group" "jenkins" {

  name        = "dp-jenkins-sg"
  description = "Security Group for DP Jenkins Controller"
  vpc_id      = aws_vpc.dp_vpc.id

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

  tags = merge(
    local.common_tags,
    {
      Name = "dp-platform-ops-sg"
    }
  )
}


#########################################################
# Jenkins Controller Ingress
#########################################################


#########################################################
# SSH - Administrator Workstation
#########################################################

resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh_admin" {

  security_group_id = aws_security_group.jenkins.id

  description = "SSH from Administrator Workstation"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = var.admin_ip
}


#########################################################
# SSH - Platform Operations Server
#########################################################

resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh_platform_ops" {

  security_group_id = aws_security_group.jenkins.id

  description = "SSH from Platform Operations Server"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  referenced_security_group_id = aws_security_group.platform_ops.id
}


#########################################################
# Jenkins Web UI - Administrator
#########################################################

resource "aws_vpc_security_group_ingress_rule" "jenkins_web_admin" {

  security_group_id = aws_security_group.jenkins.id

  description = "Jenkins Web UI"

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  cidr_ipv4 = var.admin_ip
}


#########################################################
# Jenkins Node Exporter - EKS Prometheus
#########################################################

resource "aws_vpc_security_group_ingress_rule" "node_exporter_from_eks_to_jenkins" {

  count = var.enable_eks_runtime ? 1 : 0

  security_group_id = aws_security_group.jenkins.id

  description = "Node Exporter from EKS Prometheus"

  ip_protocol = "tcp"
  from_port   = 9100
  to_port     = 9100

  referenced_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}


#########################################################
# Jenkins Prometheus Plugin - EKS Prometheus
#########################################################

resource "aws_vpc_security_group_ingress_rule" "jenkins_metrics_from_eks" {

  count = var.enable_eks_runtime ? 1 : 0

  security_group_id = aws_security_group.jenkins.id

  description = "Jenkins Prometheus metrics from EKS"

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080

  referenced_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}


#########################################################
# Jenkins Controller Egress
#########################################################

resource "aws_vpc_security_group_egress_rule" "jenkins_all_outbound" {

  security_group_id = aws_security_group.jenkins.id

  description = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}


#########################################################
# Build Agent Ingress
#########################################################


#########################################################
# SSH - Administrator Workstation
#########################################################

resource "aws_vpc_security_group_ingress_rule" "build_agent_ssh_admin" {

  security_group_id = aws_security_group.build_agent.id

  description = "SSH from Administrator Workstation"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = var.admin_ip
}


#########################################################
# SSH - Platform Operations Server
#########################################################

resource "aws_vpc_security_group_ingress_rule" "build_agent_ssh_platform_ops" {

  security_group_id = aws_security_group.build_agent.id

  description = "SSH from Platform Operations Server"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  referenced_security_group_id = aws_security_group.platform_ops.id
}


#########################################################
# Jenkins Inbound Agent Communication
#########################################################

resource "aws_vpc_security_group_ingress_rule" "build_agent_jenkins_inbound" {

  security_group_id = aws_security_group.build_agent.id

  description = "Jenkins Inbound Agent Communication"

  ip_protocol = "tcp"
  from_port   = 50000
  to_port     = 50000

  referenced_security_group_id = aws_security_group.jenkins.id
}


#########################################################
# Build Agent Node Exporter - EKS Prometheus
#########################################################

resource "aws_vpc_security_group_ingress_rule" "node_exporter_from_eks_to_build_agent" {

  count = var.enable_eks_runtime ? 1 : 0

  security_group_id = aws_security_group.build_agent.id

  description = "Node Exporter from EKS Prometheus"

  ip_protocol = "tcp"
  from_port   = 9100
  to_port     = 9100

  referenced_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}


#########################################################
# Build Agent Egress
#########################################################

resource "aws_vpc_security_group_egress_rule" "build_agent_all_outbound" {

  security_group_id = aws_security_group.build_agent.id

  description = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}


#########################################################
# Platform Operations Ingress
#########################################################


#########################################################
# SSH - Administrator Workstation
#########################################################

resource "aws_vpc_security_group_ingress_rule" "platform_ops_ssh_admin" {

  security_group_id = aws_security_group.platform_ops.id

  description = "SSH from Administrator Workstation"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = var.admin_ip
}


#########################################################
# JFrog Artifactory Web UI - Administrator
#########################################################

resource "aws_vpc_security_group_ingress_rule" "platform_ops_artifactory_admin" {

  security_group_id = aws_security_group.platform_ops.id

  description = "Artifactory Web UI from Administrator Workstation"

  ip_protocol = "tcp"
  from_port   = 8082
  to_port     = 8082

  cidr_ipv4 = var.admin_ip
}


#########################################################
# JFrog Artifactory - Jenkins Controller
#########################################################

resource "aws_vpc_security_group_ingress_rule" "artifactory_from_jenkins" {

  security_group_id = aws_security_group.platform_ops.id

  description = "Artifactory from Jenkins Controller"

  ip_protocol = "tcp"
  from_port   = 8082
  to_port     = 8082

  referenced_security_group_id = aws_security_group.jenkins.id
}


#########################################################
# JFrog Artifactory - Build Agent
#########################################################

resource "aws_vpc_security_group_ingress_rule" "artifactory_from_build_agent" {

  security_group_id = aws_security_group.platform_ops.id

  description = "Artifactory from Build Agent"

  ip_protocol = "tcp"
  from_port   = 8082
  to_port     = 8082

  referenced_security_group_id = aws_security_group.build_agent.id
}


#########################################################
# Platform Operations Node Exporter - EKS Prometheus
#########################################################

resource "aws_vpc_security_group_ingress_rule" "node_exporter_from_eks_to_platform_ops" {

  count = var.enable_eks_runtime ? 1 : 0

  security_group_id = aws_security_group.platform_ops.id

  description = "Node Exporter from EKS Prometheus"

  ip_protocol = "tcp"
  from_port   = 9100
  to_port     = 9100

  referenced_security_group_id = aws_eks_cluster.dp_cluster[0].vpc_config[0].cluster_security_group_id
}


#########################################################
# Platform Operations Egress
#########################################################

resource "aws_vpc_security_group_egress_rule" "platform_ops_all_outbound" {

  security_group_id = aws_security_group.platform_ops.id

  description = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}