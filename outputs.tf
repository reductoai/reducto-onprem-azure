# Postgres
output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgres_administrator_login" {
  value     = azurerm_postgresql_flexible_server.main.administrator_login
  sensitive = true
}

output "postgres_administrator_password" {
  value     = azurerm_postgresql_flexible_server.main.administrator_password
  sensitive = true
}

output "postgres_private_dns_zone_name" {
  value = azurerm_private_dns_zone.postgres.name
}

# Storage Account
output "storage_primary_access_key" {
  value     = azurerm_storage_account.main.primary_access_key
  sensitive = true
}

output "storage_primary_connection_string" {
  value     = azurerm_storage_account.main.primary_connection_string
  sensitive = true
}

# Private Link Service
output "reducto_private_link_service_alias" {
  value = azurerm_private_link_service.reducto.alias
}