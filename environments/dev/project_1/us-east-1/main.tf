locals {
  environment = "dev"
}

module "iam_role" {
  source = "../../../modules/iam-simple"

  name_prefix = "${local.environment}-us-east-1"
}
