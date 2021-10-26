# Get the configured default DNS Zone 
data "aws_route53_zone" "parent_zone" {
  count = (var.domain == "" ? 1 : 0)
  name = var.default_domain
}

# Create Hosted Zone for the specific subdomain name
resource "aws_route53_zone" "instance_zone" {
  count = (var.domain == "" ? 1 : 0)

  name          = local.domain
  force_destroy = true
  tags = merge(var.labels, {
    environment = var.instance_name
    domain      = local.domain
  })
}

# Create the NS record in the parent zone for the instance zone
resource "aws_route53_record" "instance_ns" {
  count = (var.domain == "" ? 1 : 0)

  zone_id = data.aws_route53_zone.parent_zone[0].zone_id
  name    = local.instance_id
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.instance_zone[0].name_servers
}

# Create any necessary records in the instance_zone
resource "aws_route53_record" "records" {

  for_each = local.route53_records

  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records

  zone_id = aws_route53_zone.instance_zone[0].zone_id
}

# Previously, we had to create CNAME records for these DKIM tokens, but now AWS
# does that automatically when it's managing the same domain in Route53.
# Leaving the code here for reference.
#s
# resource "aws_route53_record" "dkim" {count = 3

#   zone_id = aws_route53_zone.instance_zone[0].zone_id
#   name = format(
#     "%s._domainkey.%s",
#     element(aws_ses_domain_dkim.dkim.dkim_tokens, count.index),
#     local.domain,
#   )
#   type    = "CNAME"
#   ttl     = "600"
#   records = ["${element(aws_ses_domain_dkim.dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
# }

# Wait on the verification to succeed
resource "aws_ses_domain_identity_verification" "verification" {
  count = (var.domain == "" ? 1 : 0)

  domain = local.domain
  timeouts {
    create = "3m"
  }
  depends_on = [
    aws_route53_record.instance_ns,
    aws_route53_record.records,
    aws_ses_domain_dkim.dkim
  ]
}
