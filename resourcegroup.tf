# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    "env"                               = var.environment
    "location"                          = var.location
    # "tr:environment-type"             = local.env[var.environment]
    "tr:application-asset-insight-id"   = "208443"
    "tr:financial-identifier"           = "66497"
    "tr:resource-owner"                 = "SureprepLLC"
  }
}
