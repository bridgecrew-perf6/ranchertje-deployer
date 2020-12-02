terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.8"
    }
  }
}

provider aws {
  region     = var.region
  access_key = ""
  secret_key = ""
}

data aws_partition current {}
data "aws_caller_identity" "current" {}

data external thumbprint {
  program = [
    "/bin/sh",
    "${path.module}/files/thumbprint.sh",
    var.region,
  ]
}

data template_file userdata_agent {
  template = file("${path.module}/files/userdata-agent.sh")

  vars = {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    AWS_S3_BUCKET         = var.aws_s3_bucket
    AWS_USER_DATA_SCRIPT  = var.aws_user_data_script
    CLUSTER_NAME          = var.cluster_name
  }
}

data aws_ami linux_eks {
  most_recent = true
  owners = [
    "amazon"
  ]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes_version}*"]
  }
}

resource aws_cloudwatch_log_group this {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30
}

resource aws_eks_cluster this {
  name                      = var.cluster_name
  role_arn                  = aws_iam_role.cluster.arn
  version                   = var.kubernetes_version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    security_group_ids = [module.vpc.default_security_group_id]
    subnet_ids         = module.vpc.subnet_id_by_group.public
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.amazon_eks_service_policy,
    aws_cloudwatch_log_group.this,
    module.vpc
  ]
}

resource aws_iam_openid_connect_provider this {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
}

resource aws_launch_template this {
  name                   = var.cluster_name
  image_id               = data.aws_ami.linux_eks.id
  instance_type          = var.instance_type
  user_data              = base64encode(data.template_file.userdata_agent.rendered)
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]
  update_default_version = true

  tag_specifications {
    resource_type = "instance"
    tags = {
      "kubernetes.io/cluster/rancher-cluster" = "owned"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.volume_size
      volume_type = "gp2"
    }
  }
}

data null_data_source wait_for_cluster_and_kubernetes_configmap {
  inputs = {
    cluster_name             = aws_eks_cluster.this.id
    kubernetes_config_map_id = kubernetes_config_map.aws_auth.id
  }
}

resource aws_eks_node_group default {
  node_group_name = "${var.cluster_name}-nodes"

  cluster_name    = var.cluster_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.vpc.subnet_id_by_group.public

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  launch_template {
    name    = aws_launch_template.this.name
    version = "$Latest"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_worker_node_autoscale_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    data.null_data_source.wait_for_cluster_and_kubernetes_configmap
  ]
}