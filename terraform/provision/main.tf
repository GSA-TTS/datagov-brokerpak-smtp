locals {
  instance_id = "ses-${substr(sha256(var.instance_name), 0, 16)}"
  domain      = (var.domain != "" ? var.domain : "${local.instance_id}.${var.default_domain}")
  txt_verification_record = {
    name    = "_amazonses"
    type    = "TXT"
    ttl     = "600"
    records = [aws_ses_domain_identity.identity.verification_token]
  }
  dmarc_verification_record = {
    name    = "_dmarc.${local.domain}"
    type    = "TXT"
    ttl     = "600"
    records = ["v=DMARC1; p=quarantine; rua=mailto:${var.email_receipt_error}; ruf=mailto:${var.email_receipt_error}"]
  }
  spf_verification_record = {
    name    = local.domain
    type    = "TXT"
    ttl     = "600"
    records = ["v=spf1 include:amazonses.com -all"]
  }

  dkim_record0 = {
    name = format(
      "%s._domainkey.%s",
      aws_ses_domain_dkim.dkim.dkim_tokens[0],
      local.domain
    )
    type    = "CNAME"
    ttl     = "600"
    records = [ "${aws_ses_domain_dkim.dkim.dkim_tokens[0]}.dkim.amazonses.com" ]
  }
  dkim_record1 = {
    name = format(
      "%s._domainkey.%s",
      aws_ses_domain_dkim.dkim.dkim_tokens[1],
      local.domain
    )
    type    = "CNAME"
    ttl     = "600"
    records = [ "${aws_ses_domain_dkim.dkim.dkim_tokens[1]}.dkim.amazonses.com" ]
  }
  dkim_record2 = {
    name = format(
      "%s._domainkey.%s",
      aws_ses_domain_dkim.dkim.dkim_tokens[2],
      local.domain
    )
    type    = "CNAME"
    ttl     = "600"
    records = [ "${aws_ses_domain_dkim.dkim.dkim_tokens[2]}.dkim.amazonses.com" ]
  }

  required_records = {
    # Old-style (SES v1) TXT verification record
    txt_verification_record = local.txt_verification_record
    dmarc_verification_record = local.dmarc_verification_record
    spf_verification_record = local.spf_verification_record
    dkim_verification_record_0 = local.dkim_record0
    dkim_verification_record_1 = local.dkim_record1
    dkim_verification_record_2 = local.dkim_record2
  }

  # If no domain was specified, we manage the generated domain and need to
  # create the records ourselves
  route53_records = (var.domain != "" ? {} : local.required_records)

  instructions = (var.domain != "" ? "Your SMTP service was provisioned, but is not yet verified. To verify your control of the ${var.domain} domain, create the 'required_records' provided here in the ${var.domain} zone before using the service." :
  null)
}

resource "aws_ses_domain_identity" "identity" {
  domain = local.domain
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.identity.domain
}
