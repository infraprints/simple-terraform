locals {
  environment = "dev"
}

module "iam_role" {
  source = "../../../../modules/iam-simple"

  name_prefix = "${local.environment}-simple-iam"
}

output "value" {
  value = "the"
}

output "sum" {
  value = "the outcomes"
}
