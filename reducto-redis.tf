resource "azurerm_managed_redis" "reducto" {
  count = var.enable_managed_redis ? 1 : 0

  name                      = "${var.name}-redis"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  sku_name                  = var.managed_redis_sku_name
  high_availability_enabled = var.managed_redis_high_availability_enabled
  public_network_access     = "Disabled"

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
    clustering_policy                  = "EnterpriseCluster"
    eviction_policy                    = "NoEviction"
  }
}

resource "azurerm_private_dns_zone" "redis" {
  count = var.enable_managed_redis ? 1 : 0

  name                = "privatelink.redis.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count = var.enable_managed_redis ? 1 : 0

  name                  = "${var.name}-redis-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

resource "azurerm_private_endpoint" "redis" {
  count = var.enable_managed_redis ? 1 : 0

  name                = "${var.name}-redis-private-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.redis.id

  private_service_connection {
    name                           = "${var.name}-redis-private-connection"
    private_connection_resource_id = azurerm_managed_redis.reducto[0].id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis[0].id]
  }
}

locals {
  # RESP3 clients authenticate through HELLO AUTH and Azure Managed Redis
  # requires the built-in "default" username with its primary access key.
  redis_url = var.enable_managed_redis ? sensitive(format(
    "rediss://default:%s@%s:%d",
    urlencode(azurerm_managed_redis.reducto[0].default_database[0].primary_access_key),
    azurerm_managed_redis.reducto[0].hostname,
    azurerm_managed_redis.reducto[0].default_database[0].port,
  )) : null
}
