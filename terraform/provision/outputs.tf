output region { value = var.region }

output verification_record {
    value = var.domain != "" ? local.txt_verification_record : null
}

output dkim_records {
    value = var.domain != "" ? local.dkim_records : null
}

output instructions {
    value = local.instructions
}

output domain_arn {
    value = aws_ses_domain_identity.identity.arn
}