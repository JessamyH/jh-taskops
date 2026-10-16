output "frontend_bucket_name" {
  description = "S3 bucket that hosts the frontend files"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_distribution_id" {
  description = "CloudFront distribution that serves the frontend"
  value       = aws_cloudfront_distribution.frontend.id
}
