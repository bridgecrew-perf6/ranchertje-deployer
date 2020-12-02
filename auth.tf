locals {
  mapped_role = {
    rolearn : aws_iam_role.node.arn
    username : "system:node:{{EC2PrivateDNSName}}"
    groups : [
      "system:bootstrappers",
      "system:nodes",
      "system:masters"
    ]
  }

  # Convert to format needed by aws-auth ConfigMap
  configmap_roles = [
    for role in list(
      aws_iam_role.node.arn,
      aws_iam_role.cluster.arn
    ) : {
      # Work around https://github.com/kubernetes-sigs/aws-iam-authenticator/issues/153
      # Strip the leading slash off so that Terraform doesn't think it's a regex
      rolearn  = replace(role, replace("/", "/^//", ""), "")
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]
}

resource null_resource wait_for_cluster {
  depends_on = [aws_eks_cluster.this]

  provisioner "local-exec" {
    interpreter = [
      "/bin/sh",
      "-c"
    ]
    command = "curl --silent --fail --retry 60 --retry-delay 5 --retry-connrefused --insecure --output /dev/null $ENDPOINT/healthz"

    environment = {
      ENDPOINT = aws_eks_cluster.this.endpoint
    }
  }
}

data aws_eks_cluster_auth eks {
  name  = aws_eks_cluster.this.id
}

// We need to use data sources here instead of a reference to the module: https://github.com/terraform-aws-modules/terraform-aws-eks/issues/911#issuecomment-671093563
data aws_eks_cluster eks {
  name  = aws_eks_cluster.this.id
}

provider kubernetes {
  token                  = data.aws_eks_cluster_auth.eks.token
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  load_config_file       = false
  version                = ">=1.11.0"
}

resource kubernetes_config_map aws_auth {
  depends_on = [null_resource.wait_for_cluster]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      distinct(concat(
        local.configmap_roles,
        var.map_roles,
      ))
    )
    mapUsers    = yamlencode(var.map_users)
    mapAccounts = yamlencode(concat(
      list(data.aws_caller_identity.current.account_id),
      var.map_accounts
    ))
  }
}