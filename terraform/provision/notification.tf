# Create SNS topic for bounce messages
resource "aws_sns_topic" "bounce_topic" {
  count = (var.create_sns_topics ? 1 : 0)
  name  = "${var.instance_name}-bounce"
}

# Connect bounce notifications to the bounce SNS topic
resource "aws_ses_identity_notification_topic" "bounce" {
  count                    = (local.create_bounce_notification ? 1 : 0)
  topic_arn                = local.bounce_topic_sns_arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.identity.arn
  include_original_headers = true
}

# Create SNS topic for complaint messages
resource "aws_sns_topic" "complaint_topic" {
  count = (var.create_sns_topics ? 1 : 0)
  name  = "${var.instance_name}-complaint"
}

# Connect complaint notifications to the complaint SNS topic
resource "aws_ses_identity_notification_topic" "complaint" {
  count                    = (local.create_complaint_notification ? 1 : 0)
  topic_arn                = local.complaint_topic_sns_arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.identity.arn
  include_original_headers = true
}

# Create SNS topic for delivery messages
resource "aws_sns_topic" "delivery_topic" {
  count = (var.create_sns_topics ? 1 : 0)
  name  = "${var.instance_name}-delivery"
}

# Connect delivery notifications to the delivery SNS topic
resource "aws_ses_identity_notification_topic" "delivery" {
  count                    = (local.create_delivery_notification ? 1 : 0)
  topic_arn                = local.delivery_topic_sns_arn
  notification_type        = "Delivery"
  identity                 = aws_ses_domain_identity.identity.arn
  include_original_headers = true
}
