locals {
  environment = "prod"
}

module "iam_role" {
  source = "../../../modules/iam-simple"

  name_prefix = "${local.dev}"
}
