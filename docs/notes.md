# Engineering Notes

Update after each session.

## Template

### Date · Phase · Session N

- **Built:**
- **Issues and fixes:**
- **Learned:**

## Sessions

### 30 Oct 2026 · Phase 2.1 · Session 1

- **Built:** ACM certificate for `taskops.jessamyh.com` in `us-east-1` through the `aws.us_east_1` provider alias, DNS-validated with a Cloudflare CNAME. CloudFront serves the domain as an alias with `sni-only` and `TLSv1.2_2021`.
- **Issues and fixes:**
  - The Apply role can't modify IAM, so the new ACM permissions couldn't go through the pipeline. Applied `aws_iam_role_policy.terraform_plan` and `aws_iam_role_policy.terraform_apply` locally with the admin profile before merging.
  - The apply job would hang on `aws_acm_certificate_validation.frontend` until DNS validated. Added the validation CNAME first and merged only after the certificate showed `ISSUED`.
- **Learned:** CloudFront only accepts certificates from `us-east-1`, and the validation CNAME must stay in Cloudflare for auto-renewal.
