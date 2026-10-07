locals {
  frontend_origin_id = "jh-taskops-frontend.s3.ap-southeast-2.amazonaws.com-muhxbrq2uva"
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "oac-jh-taskops-frontend.s3.ap-southeast-2.amazonaws.-muhxe1vawy7"
  description                       = "Created by CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
  price_class         = "PriceClass_All"

  # Preserve the existing association; the Web ACL itself is not managed here.
  web_acl_id = "arn:aws:wafv2:us-east-1:${var.aws_account_id}:global/webacl/CreatedByCloudFront-863cda2d/5f54f480-cc14-4ab4-baec-2aafc7d2c27c"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = local.frontend_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
    connection_attempts      = 3
    connection_timeout       = 10

  }

  default_cache_behavior {
    target_origin_id       = local.frontend_origin_id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    grpc_config {
      enabled = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

  tags = {
    Name = "jh-taskops-frontend"
  }

  lifecycle {
    prevent_destroy = true
  }
}
