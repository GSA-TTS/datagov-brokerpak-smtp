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
  default = ""
}

variable region { 
  type = string 
}

variable "labels" {
  type    = map(any)
  default = {}
}
