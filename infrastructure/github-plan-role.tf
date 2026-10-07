locals {
  # Default immutable subject format for repositories created after July 15, 2026.
  github_oidc_subject = "repo:JessamyH@173381663/jh-taskops@1384763788"
  plan_role_name      = "${var.project_name}-${var.environment}-terraform-plan"
  state_bucket_arn    = "arn:aws:s3:::jessamy-lab-tfstate-956519721376"
  state_key           = "jh-taskops/prod/terraform.tfstate"
}

resource "aws_iam_role" "terraform_plan" {
  name        = local.plan_role_name
  description = "GitHub Actions Terraform plan for JH TaskOps"

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
          "token.actions.githubusercontent.com:sub" = [
            "${local.github_oidc_subject}:pull_request",
            "${local.github_oidc_subject}:ref:refs/heads/main",
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "terraform_plan" {
  name = "terraform-plan"
  role = aws_iam_role.terraform_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStateBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = local.state_bucket_arn
      },
      {
        Sid      = "ReadState"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${local.state_bucket_arn}/${local.state_key}"
      },
      {
        Sid      = "ManageStateLock"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.state_bucket_arn}/${local.state_key}.tflock"
      },
      {
        Sid    = "ReadFrontendBucketConfiguration"
        Effect = "Allow"
        Action = [
          "s3:GetBucket*",
          "s3:GetAccelerateConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetObjectLockConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ]
        Resource = aws_s3_bucket.frontend.arn
      },
      {
        Sid    = "ReadCloudFrontConfiguration"
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListTagsForResource",
        ]
        Resource = [
          aws_cloudfront_distribution.frontend.arn,
          aws_cloudfront_origin_access_control.frontend.arn,
        ]
      },
      {
        Sid    = "ReadGitHubIdentityProvider"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviderTags",
        ]
        Resource = aws_iam_openid_connect_provider.github.arn
      },
      {
        Sid    = "ReadTerraformRoles"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRoleTags",
        ]
        Resource = [
          aws_iam_role.terraform_plan.arn,
          aws_iam_role.terraform_apply.arn,
        ]
      },
    ]
  })
}
