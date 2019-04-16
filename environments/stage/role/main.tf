locals {
  environment = "stage"
}

provider "aws" {
  region = "us-east-1"
}

module "iam_role" {
  source = "../../../modules/iam-simple"

  name_prefix = "${local.environment}"
}
