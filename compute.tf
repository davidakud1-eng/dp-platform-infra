#########################################################
# DP Platform Compute Resources
# Project 1 - Traditional DevSecOps Platform
#########################################################

#########################################################
# Amazon Linux 2023 AMI
# Pinned to prevent unintended EC2 replacement
#########################################################

variable "amazon_linux_ami_id" {
  description = "Pinned Amazon Linux 2023 AMI for DP platform EC2 instances"
  type        = string
  default     = "ami-028ba4d4ccb4b7b72"
}

#########################################################
# DP Jenkins Controller
#########################################################

resource "aws_instance" "jenkins_controller" {
  ami                         = var.amazon_linux_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["us-east-2a"].id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.platform_profile.name
  associate_public_ip_address = true

  lifecycle {
    ignore_changes = [
      associate_public_ip_address
    ]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = merge(
      local.common_tags,
      {
        Name      = "dp-jenkins-controller-root"
        Component = "Storage"
        Role      = "Jenkins Controller Root Volume"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-jenkins-controller"
      Component = "Compute"
      Role      = "Jenkins Controller"
    }
  )
}

#########################################################
# DP Permanent Jenkins Build Agent
#########################################################

resource "aws_instance" "build_agent" {
  ami                         = var.amazon_linux_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["us-east-2a"].id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.build_agent.id]
  iam_instance_profile        = aws_iam_instance_profile.platform_profile.name
  associate_public_ip_address = true

  lifecycle {
    ignore_changes = [
      associate_public_ip_address
    ]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = merge(
      local.common_tags,
      {
        Name      = "dp-build-agent-root"
        Component = "Storage"
        Role      = "Permanent Jenkins Agent Root Volume"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-build-agent"
      Component = "Compute"
      Role      = "Permanent Jenkins Agent"
    }
  )
}

#########################################################
# DP Platform Operations Server
#########################################################

resource "aws_instance" "platform_ops" {

  ami                         = var.amazon_linux_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["us-east-2b"].id
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.platform_ops.id]
  iam_instance_profile        = aws_iam_instance_profile.platform_ops_profile.name
  associate_public_ip_address = true

  user_data = file("${path.module}/userdata/platform-ops.sh")

  lifecycle {
    ignore_changes = [
      associate_public_ip_address
    ]
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = merge(
      local.common_tags,
      {
        Name      = "dp-platform-ops-root"
        Component = "Storage"
        Role      = "Platform Operations Root Volume"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "dp-platform-ops"
      Component = "Compute"
      Role      = "Platform Operations"
    }
  )

}