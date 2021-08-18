# This Terraform code will create an AWS user named "ssb-smtp-broker" with the
# minimum policies in place that are needed for this brokerpak to operate. 

locals {
  this_aws_account_id    = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

module "ssb-smtp-broker-user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 4.2.0"

  create_iam_user_login_profile = false
  force_destroy                 = true
  name                          = "ssb-smtp-broker"
}

resource "aws_iam_user_policy_attachment" "smtp_broker_policies" {
  for_each = toset([
    // ACM manager: for aws_acm_certificate, aws_acm_certificate_validation
    "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",

    // Route53 manager: for aws_route53_record, aws_route53_zone
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",

    // AWS SES policy defined below
    "arn:aws:iam::${local.this_aws_account_id}:policy/${module.smtp_broker_policy.name}",

    // Uncomment if we are still missing stuff and need to get it working again
    // "arn:aws:iam::aws:policy/AdministratorAccess"
  ])
  user       = module.ssb-smtp-broker-user.iam_user_name
  policy_arn = each.key
}

module "smtp_broker_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.2.0"

  name        = "smtp_broker"
  path        = "/"
  description = "SMTP broker policy (covers SES, IAM, and supplementary Route53)"

  policy = <<-EOF
  {
    "Version":"2012-10-17",
    "Statement":
      [
        {
          "Effect":"Allow",
          "Action":[
            "ses:*"
          ],
          "Resource":"*"
        },
        {
          "Effect": "Allow",
          "Action": [
              "iam:CreateUser",
              "iam:DeleteUser",
              "iam:GetUser",

              "iam:CreateAccessKey",
              "iam:DeleteAccessKey",

              "iam:GetUserPolicy",
              "iam:PutUserPolicy",
              "iam:DeleteUserPolicy",

              "iam:CreatePolicy",
              "iam:DeletePolicy",
              "iam:GetPolicy",
              "iam:AttachUserPolicy",
              "iam:DetachUserPolicy",

              "iam:List*"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
              "route53:ListHostedZones"
          ],
          "Resource": "*"
        }
    ]
  }
  EOF
}
