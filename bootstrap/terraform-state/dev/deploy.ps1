param(
    [ValidateSet("plan", "apply", "destroy")]
    [string]$Action = "apply"
)

terraform $Action -var-file="dev.tfvars"
