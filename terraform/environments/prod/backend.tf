terraform {
  backend "s3" {
    bucket         = "sg-farmers-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-prod"
    
    # Optional: KMS encryption
    # kms_key_id = "arn:aws:kms:eu-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}