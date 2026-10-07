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

## Bootstrap GitHub OIDC

`github-oidc.tf` defines the GitHub Actions identity provider for this AWS account.
Use your local AWS profile for the initial deployment:

```sh
terraform plan -out=oidc.tfplan
terraform apply oidc.tfplan
```

Before applying this step, verify the plan only creates
`aws_iam_openid_connect_provider.github`, with no changes to existing resources.
The provider alone grants no deployment permissions.

## Bootstrap the Terraform Plan role

After the OIDC provider has been created, use the local AWS profile to plan the role:

```sh
terraform plan -out=plan-role.tfplan
terraform apply plan-role.tfplan
```

Review the saved plan before applying: it should add only the Plan role and its inline
policy (2 resources), without changing existing resources.

`github-plan-role.tf` permits PR jobs and main-branch jobs from this repository, without
a GitHub environment. The subject uses the default immutable owner/repository IDs for
this repository's creation date; custom OIDC subject templates would require updating it.
The role can read the managed resources and state, and write/delete only the state lock
object. It cannot update state or deploy resources. State read access includes all state
contents; future PR workflows must gate untrusted fork PRs before granting AWS access.

The role ARN is `arn:aws:iam::956519721376:role/jh-taskops-prod-terraform-plan`.
Permissions cover resources defined here, including reading both Terraform roles.
Actual OIDC assumption and planning under this role remain to be tested in GitHub Actions.

## Bootstrap the Terraform Apply role

After creating the Plan role, run these commands using the local administrative profile:

```sh
terraform plan -out=apply-role.tfplan
terraform apply apply-role.tfplan
```

Review before applying: expect 2 additions (Apply role and inline policy) and 1 change
(Plan policy gains read access to the Apply role). Website resources should not change.
The earlier bootstrap counts describe each incremental step, not a fresh deployment.

`github-apply-role.tf` trusts only this repository's main-branch subject, without a GitHub
environment. It shares the Plan role's read and lock permissions and adds state writes
and updates to the existing frontend bucket configuration, distribution, and OAC.
Its ARN is `arn:aws:iam::956519721376:role/jh-taskops-prod-terraform-apply`.

This role cannot modify IAM/OIDC permissions, create replacement website resources,
upload website files, or manage the associated WAF Web ACL. IAM/OIDC changes require the
local administrative profile; additional deployment capabilities require explicitly
extending the policy.

## GitHub Actions

`.github/workflows/terraform.yml` pins Terraform 1.13.5 and action commit SHAs.
PRs targeting main run formatting and validation without AWS credentials. Internal PRs
also assume the Plan role through OIDC, log the AWS identity, and run a remote-state plan.
Fork PRs and Dependabot PRs do not run the AWS plan job.

Infrastructure/workflow changes pushed to main automatically assume the Apply role,
create a saved plan, and apply that exact plan in the same job. Review changes before
merging. Manual workflow dispatch on main also runs deployment; dispatch on other
branches runs validation only. There is no GitHub environment attached to these jobs,
so OIDC uses the PR/branch subjects configured in IAM.

The AWS jobs share a concurrency group and do not cancel an active Terraform operation.
Both use the S3 backend's native locking. No AWS access-key secrets are needed, and no
state or binary plan is uploaded as an artifact. Plan output is visible in Actions logs.

After pushing the branch, open a PR to main and verify that the Plan job's STS identity
is the Plan role and the plan succeeds. After merging, verify the main job assumes the
Apply role and completes. These live OIDC and permission checks remain pending until
the workflows actually run. IAM/OIDC changes must first be applied locally because the
Apply role intentionally cannot grant or modify IAM permissions.
