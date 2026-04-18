terraform {
  backend "s3" {
    bucket         = "localmart-terraform-state"
    key            = "terraform/environments/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "localmart-terraform-locks"
    encrypt        = true
  }
}
