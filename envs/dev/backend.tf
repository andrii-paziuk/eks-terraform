terraform {
  backend "s3" {
    # Name of the bucket (bucket_name) should be as in bootstrap/terraform-state/*env* in *env*.tfvars file
    bucket       = "andrii-paziuk-eks-terraform-state"
    key          = "eks-terraform/dev/terraform.tfstate"
    region       = "ca-central-1"
    encrypt      = true
    use_lockfile = true
    profile      = "homelab"
  }
}