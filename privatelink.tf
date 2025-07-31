data "azurerm_lb" "kubernetes_internal" {
  name                = "kubernetes-internal"
  resource_group_name = azurerm_kubernetes_cluster.main.node_resource_group

  depends_on = [
    azurerm_subnet.aks,
    kubectl_manifest.nginx-ingress-controller,
    helm_release.reducto
  ]
}

resource "azurerm_private_link_service" "reducto" {
  name                = "${var.name}service"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  auto_approval_subscription_ids = [var.subscription_id]
  visibility_subscription_ids    = [var.subscription_id]

  load_balancer_frontend_ip_configuration_ids = [
    data.azurerm_lb.kubernetes_internal.frontend_ip_configuration[0].id
  ]

  nat_ip_configuration {
    name      = "${var.name}natip"
    primary   = true
    subnet_id = azurerm_subnet.aks.id
  }
}