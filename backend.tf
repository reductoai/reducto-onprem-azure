# terraform {
#   backend "azurerm" {
#     use_cli              = true                                    
#     use_azuread_auth     = false
#     resource_group_name  = "<resource-group-for-storage-account>"
#     tenant_id            = "00000000-0000-0000-0000-000000000000"
#     storage_account_name = "reductotfstate<name>"
#     container_name       = "reducto-tfstate"                              
#     key                  = "terraform.tfstate"                
#   }
# }
