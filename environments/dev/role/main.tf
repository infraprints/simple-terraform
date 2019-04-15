locals {
  environment = "dev"
}

module "iam_role" {
  source = "../../../modules/iam-simple"

  name_prefix = "${local.dev}"
}
