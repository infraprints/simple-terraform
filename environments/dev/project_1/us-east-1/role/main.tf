locals {
  environment = "dev"
}

module "iam_role" {
  source = "../../../../../modules/iam-simple"

  name_prefix = "${local.environment}-us-east-1"
}

output "value" {
  value = "${data.terraform_remote_state.top_level.value} for us-east-1"
}
