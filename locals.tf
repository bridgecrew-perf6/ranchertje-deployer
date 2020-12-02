locals {
  tagging_defaults = {
    client-prefix                 = "rancher",
    supplier-prefix               = "ch",
    client-name-location          = "06",
    client-name-role              = "NET",
    environment-region            = var.region,
    environment-type              = "production",
    environment-availability-zone = null,
    cost-center                   = "shared",
    risk-gdpr                     = "false",
    risk-operational              = "medium",
    risk-security                 = "medium",
    backups                       = ["daily", "weekly", "monthly"],
    client-owner = {
      name  = "Rancher"
      email = "info@rancher.com"
    },
    supplier-owner = {
      name  = "Laurence Kriekert"
      email = "laurence@connectholland.nl"
    }
  }

  role_numbers = {
    SQL = 1,
    LMB = 1,
    API = 1,
    STG = 1,
    NET = 1,
    AUT = 1,
    WEB = 1,
    BCK = 1,
    COM = 1,
    LOG = 1
  }
}