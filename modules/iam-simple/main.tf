resource "aws_iam_role" "simple_role" {
  name_prefix        = "${var.name_prefix}"
  path               = "/test/"
  description        = "A simple role."
  assume_role_policy = "${data.aws_iam_policy_document.assume_policy.json}"
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
