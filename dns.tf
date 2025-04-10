resource "random_pet" "name_prefix" {
  prefix = var.name
  length = 1
}

# Private DNS Zone for PostgreSQL
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking-private#use-a-private-dns-zone
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${random_pet.name_prefix.id}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.name}-pg-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# Private DNS Zone for On-prem
resource "azurerm_private_dns_zone" "onprem" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

# Private DNS Zone Virtual Network Link for On-prem
resource "azurerm_private_dns_zone_virtual_network_link" "onprem" {
  name                  = "${var.name}-onprem-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.onprem.name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}