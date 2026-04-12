# Remote state in S3 with DynamoDB locking. Critical for team collaboration:
# - S3 stores the state file (versioned, encrypted at rest)
# - DynamoDB prevents two engineers from running `apply` simultaneously
# - State files MUST be encrypted because they contain resource metadata
terraform {
  backend "s3" {
    bucket         = "datasf-terraform-state"
    key            = "compensation-platform/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "datasf-terraform-locks"
  }
}
