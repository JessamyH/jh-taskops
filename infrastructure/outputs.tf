output "frontend_bucket_name" {
  description = "S3 bucket that hosts the frontend files"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_distribution_id" {
  description = "CloudFront distribution that serves the frontend"
  value       = aws_cloudfront_distribution.frontend.id
}

output "acm_validation_records" {
  description = "CNAME records to add in Cloudflare (DNS only) so ACM can validate the certificate."
  value       = aws_acm_certificate.frontend.domain_validation_options
}

output "certificate_arn" {
  description = "ACM certificate (us-east-1) for the custom domain."
  value       = aws_acm_certificate.frontend.arn
}
