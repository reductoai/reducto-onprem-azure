variable "name" {
  description = "Resource names include this value"
  type        = string
  default     = "reducto"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "All resources will be deployed to this resource group"
  type        = string
  default     = "reducto"
}

variable "location" {
  description = "Pick region with availability zones, postgres flexible server and vmsize support for node pool https://learn.microsoft.com/en-us/azure/reliability/regions-list"
  type        = string
  default     = "westus3"
}

variable "address_space" {
  description = "The address space for VNet for all workloads"
  type        = string
  default     = "10.201.0.0/16"
}


# Postgres Configuration
variable "postgres_storage_mb" {
  description = "The storage size for the PostgreSQL Flexible Server"
  type        = number
  default     = 32768
}

variable "postgres_sku_name" {
  # Must use SKU which support pgbouncer for built-in connection pooling 
  # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-connection-pooling-best-practices#3-built-in-pgbouncer-in-azure-database-for-postgresql-flexible-server
  description = "The SKU Name for the PostgreSQL Flexible Server. The name of the SKU, follows the tier + name pattern (e.g. B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3)."
  type        = string
  default     = "GP_Standard_D4ads_v5"
}

variable "postgres_storage_tier" {
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server#storage_tier-defaults-based-on-storage_mb
  description = "The storage tier for the PostgreSQL Flexible Server"
  type        = string
  default     = "P15"
}

variable "postgres_high_availability_mode" {
  # Check availability of HA in a region
  # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/overview#azure-regions
  description = "SameZone or ZoneRedundant. Empty for no high availability"
  type        = string
  default     = "SameZone"
}

variable "postgres_pgbouncer_enabled" {
  # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-pgbouncer#enable-and-configure-pgbouncer
  # # https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-connection-pooling-best-practices#3-built-in-pgbouncer-in-azure-database-for-postgresql-flexible-server
  description = "Enable PgBouncer for built-in connection pooling"
  type        = bool
  default     = true
}

# AKS Configuration
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "default_node_pool_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "reducto_node_pool_vm_size" {
  # https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/compute-optimized/fsv2-series?tabs=sizebasic
  description = "Compute Optimized VM Size. Must be amd64 architecture."
  type        = string
  default     = "Standard_F16s_v2"
}

variable "enable_keda" {
  description = "Keda required to scale Reducto Workers based on its internal queue length"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "IP ranges to authorize access to AKS Public API Server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Reducto
variable "reducto_helm_repo_username" {
  description = "Username for Helm Registry for Reducto Helm Chart"
}

variable "reducto_helm_repo_password" {
  sensitive   = true
  description = "Password for Helm Registry for Reducto Helm Chart"
}

variable "reducto_helm_chart_version" {
  description = "Reducto Helm Chart version"
  default     = "1.10.0"
}

variable "reducto_helm_chart" {
  description = "Path to Helm Chart on OCI registry"
  default     = "oci://registry.reducto.ai/reducto-api/reducto"
}

# Private DNS Zone for Reducto on prem
variable "private_dns_zone_name" {
  description = "The dns entry will be created with <reducto_api_subdomain>.<private_dns_zone_name>"
  type        = string
  default     = "reductoai.onprem"
}

variable "reducto_api_subdomain" {
  description = "The subdomain for the Reducto API"
  type        = string
  default     = "reducto"
}