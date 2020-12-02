data aws_iam_policy_document assume_role_cluster {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource aws_iam_role cluster {
  name               = "rancher-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_cluster.json
}

resource aws_iam_role_policy_attachment amazon_eks_cluster_policy {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSClusterPolicy", data.aws_partition.current.partition)
  role       = aws_iam_role.cluster.name
}

resource aws_iam_role_policy_attachment amazon_eks_service_policy {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSServicePolicy", data.aws_partition.current.partition)
  role       = aws_iam_role.cluster.name
}

data aws_iam_policy_document cluster_elb_service_role {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInternetGateways",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSubnets"
    ]
    resources = [
      "*" // Needs to be '*' because it needs access on autoscaled EC2 instances.
    ]
  }
}

resource aws_iam_role_policy cluster_elb_service_role {
  name   = "rancher-cluster-elb-role"
  role   = aws_iam_role.cluster.name
  policy = data.aws_iam_policy_document.cluster_elb_service_role.json
}