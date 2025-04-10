# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${var.name}store"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  lifecycle {
    prevent_destroy = true
  }
}


resource "azurerm_storage_container" "reducto" {
  name                  = "${var.name}store"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

