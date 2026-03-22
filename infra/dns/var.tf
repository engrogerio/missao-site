variable "aws_region" {
  description = "region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "profile"
  type        = string
  default     = "inventsis4"
}

variable "domain_name" {
  description = "domain_name"
  type        = string
  default     = "propostas-missao.com.br"
}

variable "subdomain" {
  description = "subdomain"
  type        = string
  default     = "www"
}