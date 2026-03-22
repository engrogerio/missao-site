variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  default     = "inventsis4"
}

variable "bucket_name" {
  description = "bucket-name"
  type        = string
  default     = "partido-missao"
}

variable "iam_user_name" {
  description = "iam-user-name"
  type        = string
  default     = "missao-deploy-user"
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

variable "source_dir" {
  description = "source files path"
  type        = string
  default     = "site/"
}
