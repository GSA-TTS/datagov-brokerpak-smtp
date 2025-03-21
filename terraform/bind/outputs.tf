output "smtp_server" { value = format("email-smtp.%s.amazonaws.com", var.region) }
output "smtp_user" { value = aws_iam_access_key.access_key.id }
output "smtp_password" {
  value     = aws_iam_access_key.access_key.ses_smtp_password_v4
  sensitive = true
}
output "secret_access_key" {
  value     = aws_iam_access_key.access_key.secret
  sensitive = true
}
output "notification_webhook" { value = local.subscribed_webhook }
