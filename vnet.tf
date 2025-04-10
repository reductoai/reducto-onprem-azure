module "subnet_addrs" {
  source  = "hashicorp/subnets/cidr"
  version = "1.0.0"

  base_cidr_block = var.address_space
  networks = [
    {
      name     = "aks"
      new_bits = 2
    },
    {
      name     = "postgres"
      new_bits = 2
    },
    {
      name     = "storage"
      new_bits = 2
    },
  ]
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  address_space       = [module.subnet_addrs.base_cidr_block]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-networking-private#virtual-network-concepts
resource "azurerm_subnet" "postgres" {
  name                 = "${var.name}-postgres-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["postgres"]]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }

  lifecycle {
    ignore_changes = [service_endpoints]
  }
}

resource "azurerm_subnet" "storage" {
  name                 = "${var.name}-storage-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["storage"]]
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [module.subnet_addrs.network_cidr_blocks["aks"]]

  # So that Reducto on cluster can make calls to Computer Vision AI service
  service_endpoints = ["Microsoft.CognitiveServices"]
}
