module vpc {
  source = "git::ssh://git@github.com/ConnectHolland/terraform-aws-vpc.git?ref=tags/0.4.3"

  prefix     = "rancher"
  cidr_block = "10.169.40.0/22"

  subnet_sets = {
    public = {
      public = true,
      nacl = [
        {
          cidr   = "0.0.0.0/0"
          action = "allow"
          rule   = 100
          egress = false
        },
        {
          cidr   = "0.0.0.0/0"
          action = "allow"
          rule   = 100
          egress = true
        }
      ]
      subnets = [
        {
          cidr_block        = "10.169.41.0/24",
          availability_zone = format("%sa", var.region),
        },
        {
          cidr_block        = "10.169.42.0/24",
          availability_zone = format("%sb", var.region),
        },
        {
          cidr_block        = "10.169.43.0/24",
          availability_zone = format("%sc", var.region),
        }
      ]
    }
  }

  role_numbers     = local.role_numbers
  tagging_defaults = local.tagging_defaults
}