# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account.html#kind-1
# You must create your first Face, Text Analytics, or Computer Vision resources from the Azure portal 
# to review and acknowledge the terms and conditions. In Azure Portal, the checkbox to accept terms and
# conditions is only displayed when a US region is selected. 
# More information on Prerequisites. https://docs.microsoft.com/azure/cognitive-services/cognitive-services-apis-create-account-cli?tabs=windows#prerequisites
resource "azurerm_cognitive_account" "reducto" {
  name                = "${var.name}-vision"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "ComputerVision"
  sku_name            = "S1"

  custom_subdomain_name = "${random_pet.name_prefix.id}-reducto"

  public_network_access_enabled = true

  network_acls {
    default_action = "Deny"

    virtual_network_rules {
      subnet_id = azurerm_subnet.aks.id
    }
  }
}