
# output "website_endpoint" {
#   description = "website endpoint"
#   value       = aws_s3_bucket.website.aws_s3_bucket_website_configuration
# }

output "cloudfront_domain_name" {
  description = "cloudfront_domain_name"
  value       = aws_route53_record.cloudfront.fqdn
}

# output "acm_certificate_arn" {
#   description = "acm_certificate_arn"
#   value       = aws_cloudfront_distribution.cdn.viewer_certificate[0].acm_certificate_arn
# }


# 

# 

# cloudfront_distribution.domain_name

# cloudfront_distribution.id

# cloudfront_distribution.aliases

# cloudfront_distribution.origin_domain_name

# cloudfront_distribution.origin_id

# cloudfront_distribution.origin_path

# cloudfront_distribution.default_root_object

# cloudfront_distribution.enabled

# cloudfront_distribution.price_class

# cloudfront_distribution.comment
