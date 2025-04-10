locals {
  cluster_name = "${var.name}-aks"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = local.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku_tier = "Standard"

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
  kubernetes_version                = var.kubernetes_version


  dns_prefix = "${var.name}-aks"

  private_cluster_enabled             = false
  private_cluster_public_fqdn_enabled = false
  api_server_access_profile {
    authorized_ip_ranges = concat([var.address_space], var.cluster_endpoint_public_access_cidrs)
  }

  auto_scaler_profile {
    scale_down_delay_after_add = "15m"
    max_unready_nodes          = 10
    max_unready_percentage     = 60
    new_pod_scale_up_delay     = "0s"
    scan_interval              = "5s"
  }

  web_app_routing {
    dns_zone_ids = [azurerm_private_dns_zone.onprem.id]
  }

  dynamic "workload_autoscaler_profile" {
    for_each = var.enable_keda ? [1] : []
    content {
      keda_enabled = var.enable_keda
    }
  }

  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  default_node_pool {
    name           = "default"
    vm_size        = var.default_node_pool_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id

    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 5

    upgrade_settings {
      drain_timeout_in_minutes      = 30
      max_surge                     = "50%"
      node_soak_duration_in_minutes = 0
    }
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "reducto" {
  name                  = substr("${var.name}reducto", 0, 12)
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id

  vnet_subnet_id = azurerm_subnet.aks.id

  auto_scaling_enabled = true
  min_count            = 4
  max_count            = 50

  os_disk_size_gb = 200

  os_sku   = "Ubuntu"
  os_type  = "Linux"
  priority = "Regular"
  vm_size  = var.reducto_node_pool_vm_size

  temporary_name_for_rotation = "reductonp"

  upgrade_settings {
    drain_timeout_in_minutes      = 30
    max_surge                     = "50%"
    node_soak_duration_in_minutes = 0
  }
}
