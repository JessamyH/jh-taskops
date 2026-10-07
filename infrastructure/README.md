# Terraform configuration

Resource variables have defaults in `variables.tf`; no local variable file is required.
Keep AWS credentials in your AWS profile.
The S3 state location, encryption, and locking settings are configured in `backend.tf`.

Run from this directory:

```sh
terraform init
terraform validate
terraform plan
```

## Import the existing frontend bucket

The S3 configuration matches the existing bucket, including its CloudFront access policy.
Provider default tags are omitted to preserve the existing untagged bucket.
The bucket has `prevent_destroy` enabled to guard against accidental deletion through Terraform.

Import each resource before planning; importing writes state without changing the bucket:

```sh
terraform import aws_s3_bucket.frontend jh-taskops-frontend
terraform import aws_s3_bucket_versioning.frontend jh-taskops-frontend
terraform import aws_s3_bucket_server_side_encryption_configuration.frontend jh-taskops-frontend
terraform import aws_s3_bucket_public_access_block.frontend jh-taskops-frontend
terraform import aws_s3_bucket_policy.frontend jh-taskops-frontend
```

Review any differences and reconcile configuration with the existing resources before applying.

## Import the existing CloudFront resources

The distribution preserves its existing OAC, cache policy, certificate settings, Name tag,
and WAF Web ACL association. The Web ACL itself is not managed by this configuration.
The bucket policy references the distribution ARN, so import both CloudFront resources
before running the complete plan. Do not repeat imports for resources already in state.

```sh
terraform import aws_cloudfront_origin_access_control.frontend ERDU0X4XFF3Q4
terraform import aws_cloudfront_distribution.frontend EXCBTOO7K393B
terraform plan
```

The adoption target is `No changes` for all seven resource addresses. No apply is needed
when the imported resources match the configuration.
