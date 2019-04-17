data "terraform_remote_state" "top_level" {
  backend = "s3"

  config {
    region         = "${var.tf_state_region}"
    bucket         = "${var.tf_state_bucket}"
    dynamodb_table = "${var.tf_state_dynamo_table}"
    key            = "environments/${var.tf_environment}/project_1/role/terraform.tfstate"
  }
}

variable "tf_state_region" {}
variable "tf_state_bucket" {}
variable "tf_state_dynamo_table" {}
variable "tf_environment" {}
