# Terraform Infrastructure for Social Grants Pilot System
# Multi-cloud deployment supporting AWS, Azure, and GCP

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    # Configure your terraform state backend
    bucket = "socialgrants-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "af-south-1"
    
    # State locking
    dynamodb_table = "socialgrants-terraform-locks"
    encrypt        = true
  }
}

# Variables
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cloud_provider" {
  description = "Cloud provider (aws, azure, gcp)"
  type        = string
  default     = "aws"
}

variable "region" {
  description = "Cloud provider region"
  type        = string
  default     = "af-south-1" # South Africa region
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "socialgrants"
}

variable "department" {
  description = "Government department"
  type        = string
  default     = "dsd"
}

variable "enable_high_availability" {
  description = "Enable high availability setup"
  type        = bool
  default     = true
}

variable "enable_disaster_recovery" {
  description = "Enable disaster recovery setup"
  type        = bool
  default     = true
}

variable "database_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "kubernetes_node_count" {
  description = "Number of Kubernetes worker nodes"
  type        = number
  default     = 3
}

variable "kubernetes_node_instance_type" {
  description = "Kubernetes node instance type"
  type        = string
  default     = "m6i.large"
}

# Local values
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    Department    = var.department
    ManagedBy     = "terraform"
    Owner         = "dsd-it-team"
    CostCenter    = "dsd-grants-pilot"
    Compliance    = "popia-gdpr"
    DataClass     = "personal-sensitive"
  }

  name_prefix = "${var.project_name}-${var.environment}"
  
  # CIDR blocks for different environments
  vpc_cidrs = {
    dev     = "10.10.0.0/16"
    staging = "10.20.0.0/16"
    prod    = "10.30.0.0/16"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  count = var.cloud_provider == "aws" ? 1 : 0
  state = "available"
}

data "aws_caller_identity" "current" {
  count = var.cloud_provider == "aws" ? 1 : 0
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "random_password" "redis_password" {
  length  = 16
  special = false
}

# AWS Infrastructure
module "aws_infrastructure" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  source = "./modules/aws"

  environment                = var.environment
  region                    = var.region
  project_name              = var.project_name
  name_prefix               = local.name_prefix
  common_tags               = local.common_tags
  vpc_cidr                  = local.vpc_cidrs[var.environment]
  availability_zones        = data.aws_availability_zones.available[0].names
  enable_high_availability  = var.enable_high_availability
  enable_disaster_recovery  = var.enable_disaster_recovery
  database_instance_class   = var.database_instance_class
  database_password         = random_password.db_password.result
  redis_password           = random_password.redis_password.result
  kubernetes_node_count     = var.kubernetes_node_count
  kubernetes_node_instance_type = var.kubernetes_node_instance_type
}

# Azure Infrastructure
module "azure_infrastructure" {
  count  = var.cloud_provider == "azure" ? 1 : 0
  source = "./modules/azure"

  environment                = var.environment
  location                   = var.region
  project_name              = var.project_name
  name_prefix               = local.name_prefix
  common_tags               = local.common_tags
  vnet_cidr                 = local.vpc_cidrs[var.environment]
  enable_high_availability  = var.enable_high_availability
  database_password         = random_password.db_password.result
  redis_password           = random_password.redis_password.result
  kubernetes_node_count     = var.kubernetes_node_count
}

# GCP Infrastructure
module "gcp_infrastructure" {
  count  = var.cloud_provider == "gcp" ? 1 : 0
  source = "./modules/gcp"

  environment                = var.environment
  region                    = var.region
  project_name              = var.project_name
  name_prefix               = local.name_prefix
  common_labels             = local.common_tags
  vpc_cidr                  = local.vpc_cidrs[var.environment]
  enable_high_availability  = var.enable_high_availability
  database_password         = random_password.db_password.result
  redis_password           = random_password.redis_password.result
  kubernetes_node_count     = var.kubernetes_node_count
}

# Kubernetes configuration
module "kubernetes_apps" {
  source = "./modules/kubernetes"

  depends_on = [
    module.aws_infrastructure,
    module.azure_infrastructure,
    module.gcp_infrastructure
  ]

  environment           = var.environment
  project_name         = var.project_name
  cloud_provider       = var.cloud_provider
  database_host        = local.database_host
  database_password    = random_password.db_password.result
  redis_host          = local.redis_host
  redis_password      = random_password.redis_password.result
  domain_name         = local.domain_name
  
  # Get cluster credentials based on cloud provider
  cluster_endpoint     = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  cluster_token        = local.cluster_token
}

# Local values for outputs from modules
locals {
  database_host = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].database_endpoint, "") : 
                  var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].database_fqdn, "") :
                  var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].database_connection_name, "") : ""

  redis_host = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].redis_endpoint, "") :
               var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].redis_hostname, "") :
               var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].redis_host, "") : ""

  domain_name = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].load_balancer_dns, "") :
                var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].load_balancer_ip, "") :
                var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].load_balancer_ip, "") : ""

  cluster_endpoint = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].cluster_endpoint, "") :
                     var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].cluster_endpoint, "") :
                     var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].cluster_endpoint, "") : ""

  cluster_ca_certificate = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].cluster_ca_certificate, "") :
                           var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].cluster_ca_certificate, "") :
                           var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].cluster_ca_certificate, "") : ""

  cluster_token = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].cluster_token, "") :
                  var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].cluster_token, "") :
                  var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].cluster_token, "") : ""
}

# Outputs
output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "cloud_provider" {
  description = "Cloud provider used"
  value       = var.cloud_provider
}

output "application_url" {
  description = "Application URL"
  value       = "https://${local.domain_name}"
}

output "admin_url" {
  description = "Admin console URL"
  value       = "https://admin.${local.domain_name}"
}

output "api_url" {
  description = "API base URL"
  value       = "https://api.${local.domain_name}"
}

output "monitoring_url" {
  description = "Monitoring dashboard URL"
  value       = "https://monitoring.${local.domain_name}"
}

output "database_connection_info" {
  description = "Database connection information"
  value = {
    host     = local.database_host
    port     = 5432
    database = "socialgrants"
    username = "socialgrants"
  }
  sensitive = true
}

output "kubernetes_cluster_info" {
  description = "Kubernetes cluster information"
  value = {
    endpoint    = local.cluster_endpoint
    api_version = "v1"
  }
  sensitive = true
}

# Security compliance outputs
output "compliance_info" {
  description = "Compliance and security information"
  value = {
    encryption_at_rest     = true
    encryption_in_transit  = true
    popia_compliant       = true
    audit_logging_enabled = true
    backup_enabled        = true
    monitoring_enabled    = true
  }
}

# Cost estimation output
output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD"
  value = var.cloud_provider == "aws" ? try(module.aws_infrastructure[0].estimated_cost, 0) :
          var.cloud_provider == "azure" ? try(module.azure_infrastructure[0].estimated_cost, 0) :
          var.cloud_provider == "gcp" ? try(module.gcp_infrastructure[0].estimated_cost, 0) : 0
}