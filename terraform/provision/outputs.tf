output region { value = var.region }

output required_records {
  value = var.domain != "" ? local.required_records_as_string : null
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
