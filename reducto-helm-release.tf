locals {
  reducto_host = "${var.reducto_api_subdomain}.${var.private_dns_zone_name}"
}

resource "helm_release" "reducto" {
  namespace        = "reducto"
  name             = "reducto"
  create_namespace = true

  repository_username = var.reducto_helm_repo_username
  repository_password = var.reducto_helm_repo_password

  chart   = var.reducto_helm_chart
  version = var.reducto_helm_chart_version
  wait    = true
  timeout = var.helm_release_timeout

  values = concat(
    [
      file("values/reducto.yaml"),
      <<-EOT
    ingress:
      host: ${local.reducto_host}
      className: nginx-internal
      annotations:
        nginx.ingress.kubernetes.io/server-alias: "*.${var.private_dns_zone_name}"
    env:
      DATABASE_URL: ${local.database_url}
      AZURE_STORAGE_CONTAINER: ${azurerm_storage_container.reducto.name}
      AZURE_STORAGE_ACCOUNT_NAME: ${azurerm_storage_account.main.name}
      AZURE_STORAGE_CONNECTION_STRING: ${azurerm_storage_account.main.primary_connection_string}
      AZURE_STORAGE_ACCOUNT_KEY: ${azurerm_storage_account.main.primary_access_key}
      AZURE_VISION_ENDPOINT: ${azurerm_cognitive_account.reducto.endpoint}
      AZURE_VISION_KEY: ${azurerm_cognitive_account.reducto.primary_access_key}
%{if var.enable_managed_redis~}
      REDIS_URL: ${local.redis_url}
%{endif~}
%{if var.enable_managed_redis~}
    redis:
      enabled: false
%{endif~}
      EOT
    ],
    [for values_path in var.reducto_extra_values_files : file(values_path)],
  )

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_kubernetes_cluster_node_pool.reducto,
    azurerm_postgresql_flexible_server_database.reducto,
    azurerm_storage_container.reducto,
    azurerm_cognitive_account.reducto,
    azurerm_private_endpoint.redis,
  ]
}
