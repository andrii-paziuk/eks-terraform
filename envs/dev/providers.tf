# AWS credentials are provided through an AWS CLI profile.
# Set the profile name to one listed by `aws configure list-profiles`.
provider "aws" {
  region  = var.aws_region
  profile = "homelab"
}