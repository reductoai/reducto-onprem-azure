resource "random_password" "administrator_password" {
  length  = 16
  upper   = true
  lower   = true
  numeric = true
  special = false
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.name}-postgres"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  administrator_login    = local.database_admin_username
  administrator_password = random_password.administrator_password.result

  storage_mb        = var.postgres_storage_mb
  auto_grow_enabled = true
  storage_tier      = var.postgres_storage_tier

  sku_name = var.postgres_sku_name

  public_network_access_enabled = false

  dynamic "high_availability" {
    for_each = length(var.postgres_high_availability_mode) > 0 ? [1] : []
    content {
      mode = var.postgres_high_availability_mode
    }
  }

  authentication {
    password_auth_enabled         = true
    active_directory_auth_enabled = false
  }

  delegated_subnet_id = azurerm_subnet.postgres.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  lifecycle {
    # Terraform to not migrate the PostgreSQL Flexible Server back to it's primary Availability Zone after a fail-over.
    ignore_changes = [
      high_availability[0].standby_availability_zone,
      zone,
    ]

    prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "reducto" {
  name      = "reducto"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_enabled" {
  count     = var.postgres_pgbouncer_enabled ? 1 : 0
  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "True"
}

locals {
  database_admin_username = "reductoadmin"
  database_port           = var.postgres_pgbouncer_enabled ? 6432 : 5432
  database_url            = sensitive("postgresql://${local.database_admin_username}:${random_password.administrator_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:${local.database_port}/reducto?sslmode=require")
}