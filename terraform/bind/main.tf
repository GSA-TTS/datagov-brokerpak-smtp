locals {
  instance_id = "ses-${substr(sha256(var.instance_name), 0, 16)}"
  user_name = "${local.instance_id}-${var.user_name}"
}

resource "aws_iam_user" "user" {
    name = local.user_name
    path = "/cf/"
}

resource "aws_iam_access_key" "access_key" {
    user = aws_iam_user.user.name
}

resource "aws_iam_user_policy" "user_policy" {
    name   = format("%s-p", local.user_name)

    user   = aws_iam_user.user.name

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action":[
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": "${var.domain_arn}"
    }
  ]
}
EOF
}