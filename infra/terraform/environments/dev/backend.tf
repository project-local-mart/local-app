terraform {
  backend "s3" {
    # Fill these in after running infra/bootstrap.
    bucket         = "localmart-terraform-state" # bootstrap output: state_bucket_name
    key            = "terraform/environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "localmart-terraform-locks" # bootstrap output: lock_table_name
    encrypt        = true
  }
}
