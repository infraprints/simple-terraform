resource "aws_iam_role" "simple_role" {
  name_prefix = "${var.name_prefix}"
  path        = "/test/"
  description = "A simple role."
}
