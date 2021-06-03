locals {
  instance_id = "ses-${substr(sha256(var.instance_name), 0, 16)}"
}

data "aws_route53_zone" "zone" {
  name = var.domain
}

resource "aws_ses_domain_identity" "identity" {
  domain = var.domain
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "_amazonses.${local.instance_id}.${aws_ses_domain_identity.identity.id}."
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.identity.verification_token]
}

resource "aws_ses_domain_identity_verification" "verification" {
  domain = aws_ses_domain_identity.identity.id
  depends_on = [aws_route53_record.record]
}
