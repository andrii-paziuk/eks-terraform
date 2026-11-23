module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.30.2"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # Networking
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # API endpoint access
  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Authentication
  authentication_mode = "API"

  enable_cluster_creator_admin_permissions = true

  # OIDC for future IRSA integrations
  enable_irsa = true

  # Kubernetes secrets encryption
  # AWS-owned encryption key is used.
  # We will introduce a persistent customer-managed KMS key later.
  encryption_config = null

  # Control plane logging
  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  cloudwatch_log_group_retention_in_days = 30

  # EKS managed add-ons
  addons = {
    coredns = {
      most_recent = true
    }

    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
  }

  # Managed Node Groups
  eks_managed_node_groups = {
    system = {
      name = "${var.cluster_name}-system"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      subnet_ids = var.private_subnet_ids

      disk_size = 30

      update_config = {
        max_unavailable = 1
      }

      labels = {
        role        = "system"
        environment = "dev"
      }

      tags = var.tags
    }
  }

  tags = var.tags
}
