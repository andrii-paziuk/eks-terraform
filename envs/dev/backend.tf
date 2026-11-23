terraform {
  backend "s3" {
    bucket       = "homelab-eks-terraform-state"
    key          = "eks/dev/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
  }
}