terraform {
  backend "s3" {
    bucket         = "eks-security-non-prod-terraform-state-ac97c39c"
    key            = "applications/non-prod/alb-controller/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "eks-security-non-prod-terraform-lock"
    encrypt        = true
  }
}
