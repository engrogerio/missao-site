# Read dns stack outputs
data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "missao-tf-state-bucket"
    key    = "infra/dns/terraform.tfstate"
    region = "us-east-1"
    profile = "inventsis4"
  }
}

terraform {
  backend "s3" {
    bucket  = "missao-tf-state-bucket"
    key     = "infra/app/terraform.tfstate"
    region  = "us-east-1"
    profile = "inventsis4"
  }
}

############################
# S3
############################

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  force_destroy = true
}

resource "aws_s3_object" "object" {
  # Use fileset to enumerate all files in the local directory (including subdirectories with "**")
  for_each = fileset("static-website-files/", "**")
  
  bucket = aws_s3_bucket.website.id
  # Set the S3 object key to be the same as the file path relative to the source directory
  key    = each.value
  # Specify the source file path
  source = "static-website-files/${each.value}"
  
  # Set the ETag to trigger an update only if the file changes
  etag = filemd5("static-website-files/${each.value}")
  
  # Optional: Automatically set the Content-Type based on the file extension
  content_type = lookup(local.mime_types, regex("\\.([^.]+)$", each.value)[0], "application/octet-stream")

  cache_control = (
    each.value == "temas.json"
  ) ? "no-cache" : "public, max-age=31536000, immutable"
}

# 4. Define local variable for common MIME types (for content_type)
locals {
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "jpg"  = "image/jpeg"
    "png"  = "image/png"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
  }
}

resource "aws_s3_bucket_ownership_controls" "website_bucket" {
  bucket = aws_s3_bucket.website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################
# CLOUDFRONT
############################

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac"
  description                       = "OAC for private S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = ["${var.subdomain}.${var.domain_name}", var.domain_name]

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  }
  ordered_cache_behavior {
    path_pattern     = "temas.json"
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id = aws_cloudfront_cache_policy.no_cache_json.id
  }
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  viewer_certificate {
    acm_certificate_arn      = data.terraform_remote_state.dns.outputs.cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

############################
# S3 BUCKET POLICY
############################

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

############################
# ROUTE53 RECORDS
############################

resource "aws_route53_record" "cloudfront_root" {
  name    = var.domain_name
  type    = "A"
  zone_id = data.terraform_remote_state.dns.outputs.zone_id

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_www" {
  zone_id = data.terraform_remote_state.dns.outputs.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.cdn.domain_name]
}

resource "aws_cloudfront_cache_policy" "no_cache_json" {
  name = "no-cache-json"

  default_ttl = 0
  max_ttl     = 1
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

