#==============================================================================
# DATA SOURCES
#==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

#==============================================================================
# KUBERNETES PROVIDER CONFIGURATION
#==============================================================================

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

#==============================================================================
# IRSA ROLES FOR SYSTEM COMPONENTS
#==============================================================================

# VPC CNI IRSA Role
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-vpc-cni-irsa"

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.tags
}

# EBS CSI Driver IRSA Role
module "ebs_csi_driver_irsa" {
  count = var.enable_ebs_csi_driver ? 1 : 0
  
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi-driver-irsa"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

# AWS Load Balancer Controller IRSA Role
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}

# External DNS IRSA Role (optional)
module "external_dns_irsa" {
  count = var.enable_external_dns ? 1 : 0
  
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-external-dns"

  attach_external_dns_policy = true
  external_dns_hosted_zone_arns = var.external_dns_hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }

  tags = var.tags
}

# Cert Manager IRSA Role (optional)
module "cert_manager_irsa" {
  count = var.enable_cert_manager ? 1 : 0
  
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-cert-manager"

  attach_cert_manager_policy = true
  cert_manager_hosted_zone_arns = var.cert_manager_hosted_zone_arns

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = [
        "cert-manager:cert-manager",
        "cert-manager:cert-manager-cainjector",
        "cert-manager:cert-manager-webhook"
      ]
    }
  }

  tags = var.tags
}

# ArgoCD IRSA Role for ECR access (optional)
module "argocd_irsa" {
  count = var.enable_argocd_ecr_access ? 1 : 0
  
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-argocd"

  role_policy_arns = {
    ecr_policy = aws_iam_policy.argocd_ecr[0].arn
  }

  oidc_providers = {
    main = {
      provider_arn = var.oidc_provider_arn
      namespace_service_accounts = [
        "argocd:argocd-application-controller",
        "argocd:argocd-server"
      ]
    }
  }

  tags = var.tags
}

# ECR access policy for ArgoCD
resource "aws_iam_policy" "argocd_ecr" {
  count = var.enable_argocd_ecr_access ? 1 : 0
  
  name        = "${var.cluster_name}-argocd-ecr"
  description = "IAM policy for ArgoCD ECR access"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

#==============================================================================
# AWS LOAD BALANCER CONTROLLER DEPLOYMENT
#==============================================================================

# Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.aws_load_balancer_controller_irsa.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }

  depends_on = [module.aws_load_balancer_controller_irsa]
}

# AWS Load Balancer Controller Helm Chart
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.aws_load_balancer_controller_chart_version

  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = data.aws_region.current.name
      vpcId       = var.vpc_id
      
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
      }
      
      logLevel     = var.aws_load_balancer_controller_log_level
      replicaCount = 2
      
      # Security settings
      securityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        runAsNonRoot            = true
        capabilities = {
          drop = ["ALL"]
        }
      }
      
      podSecurityContext = {
        fsGroup = 65534
      }
      
      # Resource limits
      resources = {
        limits = {
          cpu    = "200m"
          memory = "500Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "200Mi"
        }
      }
      
      # Node selection
      nodeSelector = {}
      tolerations  = []
      
      # Webhook configuration
      webhookCertDir = "/tmp/k8s-webhook-server/serving-certs"
    })
  ]

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller,
    module.aws_load_balancer_controller_irsa
  ]
}

#==============================================================================
# SECURITY GROUPS FOR ALB COMMUNICATION
#==============================================================================

# Security group for ALB to communicate with nodes
resource "aws_security_group" "alb_to_nodes" {
  name_prefix = "${var.cluster_name}-alb-to-nodes-"
  vpc_id      = var.vpc_id
  description = "Security group for ALB to nodes communication"

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "HTTPS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "NodePort range for ALB health checks"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-to-nodes"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security group rules: Allow ALB to communicate with nodes
resource "aws_security_group_rule" "cluster_ingress_alb_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_to_nodes.id
  security_group_id        = var.node_security_group_id
  description              = "ALB HTTP to nodes"
}

resource "aws_security_group_rule" "cluster_ingress_alb_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_to_nodes.id
  security_group_id        = var.node_security_group_id
  description              = "ALB HTTPS to nodes"
}

resource "aws_security_group_rule" "cluster_ingress_alb_nodeports" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_to_nodes.id
  security_group_id        = var.node_security_group_id
  description              = "ALB to nodes NodePort range"
}

#==============================================================================
# ARGOCD HELM DEPLOYMENT (OPTIONAL)
#==============================================================================

# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  count = var.enable_argocd_deployment ? 1 : 0

  metadata {
    name = "argocd"
    
    annotations = {
      "iam.amazonaws.com/permitted" = module.argocd_irsa[0].iam_role_arn
    }
  }

  depends_on = [var.enable_argocd_ecr_access ? module.argocd_irsa[0] : null]
}

# ArgoCD Service Account
resource "kubernetes_service_account" "argocd_application_controller" {
  count = var.enable_argocd_deployment ? 1 : 0

  metadata {
    name      = "argocd-application-controller"
    namespace = kubernetes_namespace.argocd[0].metadata[0].name
    
    annotations = var.enable_argocd_ecr_access ? {
      "eks.amazonaws.com/role-arn"               = module.argocd_irsa[0].iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    } : {}
  }

  depends_on = [kubernetes_namespace.argocd]
}

# ArgoCD Helm Chart
resource "helm_release" "argocd" {
  count = var.enable_argocd_deployment ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd[0].metadata[0].name
  version    = var.argocd_chart_version

  values = [
    yamlencode({
      global = {
        domain = var.argocd_domain
      }
      
      controller = {
        serviceAccount = {
          create = false
          name   = kubernetes_service_account.argocd_application_controller[0].metadata[0].name
        }
      }
      
      server = {
        service = {
          type = "ClusterIP"
        }
        
        ingress = {
          enabled     = var.enable_argocd_ingress
          ingressClassName = "alb"
          annotations = {
            "alb.ingress.kubernetes.io/scheme"        = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"   = "ip"
            "alb.ingress.kubernetes.io/certificate-arn" = var.argocd_certificate_arn
            "alb.ingress.kubernetes.io/ssl-redirect"  = "443"
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            "alb.ingress.kubernetes.io/security-groups" = var.alb_security_group_id
          }
          hosts = [var.argocd_domain]
          tls = [{
            secretName = "argocd-server-tls"
            hosts      = [var.argocd_domain]
          }]
        }
      }
      
      # Resource specifications
      controller = {
        resources = {
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
          requests = {
            cpu    = "250m"
            memory = "256Mi"
          }
        }
      }
      
      server = {
        resources = {
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.aws_load_balancer_controller,
    kubernetes_service_account.argocd_application_controller
  ]
}

#==============================================================================
# WAIT FOR RESOURCES TO BE READY
#==============================================================================

# Wait for ALB controller to be ready
resource "time_sleep" "wait_for_alb_controller" {
  depends_on = [helm_release.aws_load_balancer_controller]
  
  create_duration = "60s"
}

# Wait for ArgoCD to be ready
resource "time_sleep" "wait_for_argocd" {
  count = var.enable_argocd_deployment ? 1 : 0
  
  depends_on = [helm_release.argocd]
  
  create_duration = "30s"
}