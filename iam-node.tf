data aws_iam_policy_document assume_role_node {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document amazon_eks_worker_node_autoscale_policy {
  statement {
    sid = "AllowToScaleEKSNodeGroupAutoScalingGroup"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    resources = [
      "*" // Needs to be '*' because it needs access on autoscaled EC2 instances.
    ]
  }
}

resource aws_iam_policy amazon_eks_worker_node_autoscale_policy {
  name   = "eks-${var.cluster_name}-autoscale"
  policy = data.aws_iam_policy_document.amazon_eks_worker_node_autoscale_policy.json
}

resource aws_iam_role node {
  name               = "rancher-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_node.json
}

resource aws_iam_role_policy_attachment amazon_eks_worker_node_autoscale_policy {
  policy_arn = aws_iam_policy.amazon_eks_worker_node_autoscale_policy.arn
  role       = aws_iam_role.node.name
}

resource aws_iam_role_policy_attachment amazon_eks_worker_node_policy {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSWorkerNodePolicy", data.aws_partition.current.partition)
  role       = aws_iam_role.node.name
}

resource aws_iam_role_policy_attachment amazon_eks_cni_policy {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKS_CNI_Policy", data.aws_partition.current.partition)
  role       = aws_iam_role.node.name
}

resource aws_iam_role_policy_attachment amazon_ec2_container_registry_read_only {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", data.aws_partition.current.partition)
  role       = aws_iam_role.node.name
}
