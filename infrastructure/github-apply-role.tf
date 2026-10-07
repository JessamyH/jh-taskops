resource "aws_iam_role" "terraform_apply" {
  name        = "${var.project_name}-${var.environment}-terraform-apply"
  description = "GitHub Actions Terraform apply from JH TaskOps main"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "${local.github_oidc_subject}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "terraform_apply" {
  name = "terraform-apply"
  role = aws_iam_role.terraform_apply.id

  # Share plan read/lock access, then add writes for the existing website resources.
  # IAM/OIDC permission changes continue to use the local administrative profile.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(jsondecode(aws_iam_role_policy.terraform_plan.policy).Statement, [
      {
        Sid      = "WriteState"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${local.state_bucket_arn}/${local.state_key}"
      },
      {
        Sid    = "UpdateFrontendBucketConfiguration"
        Effect = "Allow"
        Action = [
          "s3:PutBucketVersioning",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketTagging",
        ]
        Resource = aws_s3_bucket.frontend.arn
      },
      {
        Sid    = "UpdateFrontendDistribution"
        Effect = "Allow"
        Action = [
          "cloudfront:UpdateDistribution",
          "cloudfront:TagResource",
          "cloudfront:UntagResource",
        ]
        Resource = aws_cloudfront_distribution.frontend.arn
      },
      {
        Sid      = "UpdateFrontendOriginAccessControl"
        Effect   = "Allow"
        Action   = ["cloudfront:UpdateOriginAccessControl"]
        Resource = aws_cloudfront_origin_access_control.frontend.arn
      },
    ])
  })
}
