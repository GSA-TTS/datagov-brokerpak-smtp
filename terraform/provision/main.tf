locals {
  instance_id = "ses-${substr(sha256(var.instance_name), 0, 16)}"

  manage_domain = (var.domain == "" ? true : false)
  domain        = (local.manage_domain ? "${local.instance_id}.${var.default_domain}" : var.domain)
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

  dkim_records = [for i, token in aws_ses_domain_dkim.dkim.dkim_tokens :
    {
      name    = "${token}._domainkey.${local.domain}"
      type    = "CNAME"
      ttl     = "600"
      records = ["${token}.dkim.amazonses.com"]
    }
  ]

  required_records = {
    txt_verification_record   = local.txt_verification_record
    dmarc_verification_record = local.dmarc_verification_record
    spf_verification_record   = local.spf_verification_record
    dkim_record_0             = local.dkim_records[0]
    dkim_record_1             = local.dkim_records[1]
    dkim_record_2             = local.dkim_records[2]
  }

  # Generate string output usable for pasting into HCL elsewhere if needed
  required_records_as_string = <<-EOT

  {%{for key, value in local.required_records}
    ${key} = {
      name    = "${value.name}"
      type    = "${value.type}"
      ttl     = "${value.ttl}"
      records = [%{for record in value.records}"${record}"%{endfor~}]
    } %{endfor}
  }
  EOT

  # If no domain was specified, we manage the generated domain and need to
  # create the records ourselves
  required_records_flatter = {
    for key, value in local.required_records :
    key => {
      id     = key
      name   = value.name
      type   = value.type
      ttl    = value.ttl
      record = value.records[0]
    }
  }

  route53_records = (local.manage_domain ? local.required_records_flatter : {})

  # SNS topic locals
  create_bounce_notification    = (var.create_sns_topics || var.notifications_bounce_topic_arn != "")
  bounce_topic_sns_arn          = (var.create_sns_topics ? aws_sns_topic.bounce_topic[0].arn : var.notifications_bounce_topic_arn)
  create_complaint_notification = (var.create_sns_topics || var.notifications_complaint_topic_arn != "")
  complaint_topic_sns_arn       = (var.create_sns_topics ? aws_sns_topic.complaint_topic[0].arn : var.notifications_complaint_topic_arn)
  create_delivery_notification  = (var.create_sns_topics || var.notifications_delivery_topic_arn != "")
  delivery_topic_sns_arn        = (var.create_sns_topics ? aws_sns_topic.delivery_topic[0].arn : var.notifications_delivery_topic_arn)

  instructions = (local.manage_domain ? null : "Your SMTP service was provisioned, but is not yet verified. To verify your control of the ${var.domain} domain, create the 'required_records' provided here in the ${var.domain} zone before using the service.")
}

resource "aws_ses_domain_identity" "identity" {
  domain = local.domain
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.identity.domain
}
