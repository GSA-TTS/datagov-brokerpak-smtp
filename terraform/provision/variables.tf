variable "domain" {
  type        = string
  description = "Domain from which to send mail"
  default     = ""
}

variable "default_domain" {
  type        = string
  description = "Fallback domain to use if none was supplied"
  default     = "example.gov"
}

variable "instance_name" {
  type    = string
}

variable "region" {
  type = string
}

variable "email_receipt_error" {
  type = string
}

variable "labels" {
  type    = map(any)
  default = {}
}

variable "create_sns_topics" {
  type = bool
  description = "Toggle whether to create SNS topics for feedback notifications"
  default = false
}

variable "notifications_bounce_topic_arn" {
  type = string
  description = "ARN of an SNS topic to subscribe bounce messages to"
  default = ""
}

variable "notifications_complaint_topic_arn" {
  type = string
  description = "ARN of an SNS topic to subscribe complaint messages to"
  default = ""
}

variable "notifications_delivery_topic_arn" {
  type = string
  description = "ARN of an SNS topic to subscribe delivery messages to"
  default = ""
}
