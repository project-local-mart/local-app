output "state_bucket_name" {
  description = "S3 bucket name — use in environment backend.tf as bucket."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name — use in environment backend.tf as dynamodb_table."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "lock_table_arn" {
  description = "DynamoDB table ARN."
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "terraform_deployer_role_arn" {
  description = "ARN of the TerraformDeployer IAM role."
  value       = aws_iam_role.terraform_deployer.arn
}

output "ci_role_arn" {
  description = "ARN of the CI IAM role (assumed by GitHub Actions via OIDC)."
  value       = aws_iam_role.ci.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}
