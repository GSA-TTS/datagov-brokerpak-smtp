output region { value = var.region }

output verification_record {
  value = var.domain != "" ? local.txt_verification_record : null
}

output dkim_records {
  value = var.domain != "" ? local.dkim_records : null
}

output spf_records {
  value = var.domain != "" ? local.spf_records : null
}

output dmarc_records {
  value = var.domain != "" ? local.dmarc_records : null
}

output email_receipt_error {
    value = var.email_receipt_error
}

output instructions {
  value = local.instructions
}

output domain_arn {
  value = aws_ses_domain_identity.identity.arn
}
