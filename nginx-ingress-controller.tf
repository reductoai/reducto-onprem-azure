# ConfigMap for NGINX Ingress Controller configuration
# Security: Disable TLS 1.0 and TLS 1.1, only allow TLS 1.2 and TLS 1.3
resource "kubectl_manifest" "nginx-ingress-config" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nginx-internal-nginx-ingress-controller
      namespace: app-routing-system
    data:
      ssl-protocols: "TLSv1.2 TLSv1.3"
    YAML

  depends_on = [
    azurerm_kubernetes_cluster.main,
  ]
}

resource "kubectl_manifest" "nginx-ingress-controller" {
  yaml_body = <<-YAML
    apiVersion: approuting.kubernetes.azure.com/v1alpha1
    kind: NginxIngressController
    metadata:
      name: nginx-internal
    spec:
      ingressClassName: nginx-internal
      controllerNamePrefix: nginx-internal
      loadBalancerAnnotations: 
        service.beta.kubernetes.io/azure-load-balancer-internal: "true"
        service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "${azurerm_subnet.aks.name}"
    YAML

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_subnet.aks,
    azurerm_role_assignment.aks_network_contributor,
    azurerm_role_assignment.web_app_routing_dns_contributor,
    kubectl_manifest.nginx-ingress-config
  ]
}

# For internal loadbalancer
# https://learn.microsoft.com/en-us/azure/aks/internal-lb?tabs=set-service-annotations#use-private-networks
resource "azurerm_role_assignment" "aks_network_contributor" {
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.main.id
}

# To create records in the private DNS zone by web app routing identity
resource "azurerm_role_assignment" "web_app_routing_dns_contributor" {
  scope                = azurerm_private_dns_zone.onprem.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.web_app_routing[0].web_app_routing_identity[0].object_id
}
