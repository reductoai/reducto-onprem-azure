# Reducto

Install Reducto on Azure Kubernetes Service using Terraform.

![Reducto on-prem Architecture for Azure](./reducto-architecture-on-azure.png)

## Overview

The project creates [Helm Release](./reducto-helm-release.tf) for Reducto on AKS in `reducto` namespace. And creates following required dependencies:
1. [Azure Database for PostgreSQL flexible server](./reducto-postgres.tf) with PgBouncer for connection pooling
2. [Azure Blob Storage](./reducto-storage.tf)
3. [Azure AI Service | ComputerVision](./reducto-computervision.tf)
4. AKS supported in-cluster Keda for autoscaling of in-cluster Reducto workers
5. AKS supported cluster autoscaler for Reducto node pool autoscaling
6. AKS supported nginx ingress controller for Reducto Ingress
7. Private DNS Zone for assigning DNS to Nginx Load Balancer / Reducto Ingress
8. Azure Managed Redis, reachable only through a private endpoint, for the Reducto queue backend

This project demonstrates fully working cluster that's required to run Reducto.

## Azure Quotas

Reducto utilizes compute optimized instances, for autoscaling to work ensure that [Compute Quota on Azure Portal](https://portal.azure.com/#view/Microsoft_Azure_Capacity/QuotaMenuBlade/~/overview) in your desired region has appropriate capacity:

1. Quota for choosen `var.reducto_node_pool_vm_size` family of vCPUs
2. Quota for Total Regional vCPUs


## Helm Chart

To obtain or inspect Helm Chart and available configurations in `values.yaml`

```
# Login
helm registry login registry.reducto.ai \
    --username <your-username>  \
    --password <your-password>

# Get latest Helm Chart
helm pull oci://registry.reducto.ai/reducto-api/reducto
```

## Security

AKS node pool, Postgres DB, Load Balancer for ingress are all created in subnets with only private IP ranges. These subnets get [default outbound access](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access).

For bootstrapping in-cluster resources, AKS is provisioned with public endpoint enabled.

Access to this public API server (before or after provisioning) can be restricted with `var.cluster_endpoint_public_access_cidrs`.



### Terraform State

Terraform plan and apply with locally managed `terraform.tfstate` state file for development & testing purposes.

For production workload setup a [remote state backend](https://developer.hashicorp.com/terraform/language/backend).

### Configuration

Update `variables.tf` with desired configuration.

Aternatively, create `terraform.tfvars` with following contents at a minimum:

```
subscription_id="todo"
reducto_helm_chart_version = "todo"
reducto_helm_repo_username = "todo"
reducto_helm_repo_password = "todo"
name = "todo"
private_dns_zone_name = "todo.onprem"
```

The default chart version is `1.12.6`. Azure Managed Redis is opt-in so the
existing deployment behavior remains unchanged while Redis-backed workloads
are disabled. Set `enable_managed_redis = true` to provision it; Terraform then
passes a TLS `REDIS_URL` to the chart, sets the Streaq Redis hash tag required
by EnterpriseCluster, and disables the chart's in-cluster Redis.
`Balanced_B0` is the default cache SKU; production installations should size
`managed_redis_sku_name` for their queue throughput.

Chart `1.12.6` selects traffic distribution from the Kubernetes version, so the
old explicit `PreferClose` workaround is no longer needed. The included
`dnsConfigNoAAAA: false` override remains for this portable dual-stack
deployment.

## Streaq bridge (chart 1.12.6)

For the v1.12.6 → v1.13 migration, pin the chart, provision managed Redis, and
layer the worker topology through `reducto_extra_values_files`. Keep the legacy
worker enabled during the bridge and start every rollout ratio at `0`; follow
the migration runbook for the full drain and ramp procedure.

```hcl
reducto_helm_chart_version = "1.12.6"
enable_managed_redis       = true
reducto_extra_values_files = ["streaq-bridge.yaml"]
```

`streaq-bridge.yaml`:

```yaml
env:
  WORKER_PROVIDER: STREAQ_LOCAL
  PARSE_STREAQ_TRAINABLE_ROLLOUT_RATIO: "0"
  PARSE_STREAQ_NON_TRAINABLE_ROLLOUT_RATIO: "0"
  STREAQ_CPU_WORKER_ROLLOUT_PCT: "0"
  STREAQ_CPU_COMPLETION_TRAINABLE_ROLLOUT_PCT: "0"
  STREAQ_CPU_COMPLETION_NON_TRAINABLE_ROLLOUT_PCT: "0"
streaqWorkers:
  io:
    enabled: true
    workerName: io
    useFullImage: true
  cpu:
    enabled: true
    workerName: cpu
    useFullImage: true
worker:
  enabled: true
```

Azure Cache for Redis is being retired, so new deployments use Azure Managed
Redis. The cache has public network access disabled and uses Azure Private Link
plus the `privatelink.redis.azure.net` private DNS zone.

### Provisioning

Apply Terraform

```
terraform init
terraform plan
terraform apply
```

For a brand-new cluster, this legacy monolithic root requires two stages
because its Kubernetes and Helm providers cannot connect until AKS exists. The
first stage must be reviewed as a saved plan and should contain only Azure
infrastructure and its dependencies:

```
terraform plan \
  -target=azurerm_kubernetes_cluster.main \
  -target=azurerm_kubernetes_cluster_node_pool.reducto \
  -target=azurerm_private_endpoint.redis \
  -out=bootstrap.tfplan
terraform apply bootstrap.tfplan

terraform plan -out=platform.tfplan
terraform apply platform.tfplan
```

Do not reuse either saved plan after configuration or remote state changes.
The consolidated `onprem-infra` repository avoids targeted bootstrapping by
using separate Azure infrastructure and platform roots and is preferred for
new installations.

### DNS

FQDN in the form of `${var.reducto_api_subdomain}.${var.private_dns_zone_name}` for Reducto API can be resolved within Virtual Network. 

To get Load Balancer private IP for other custom DNS setup:

```
kubectl get ingress -n reducto -o jsonpath='{.items[0].status.loadBalanc
er.ingress[0].ip}'
```

### Access Reducto

Reducto will only be accesible to resources on Virtual Network, or other networks peering into it. 

To access Reducto locally, port forward your local 4567 to Reducto service via AKS API server:

```
kubectl port-forward service/reducto-reducto-http 4567:80 -n reducto

# Access Reducto
curl localhost:4567
```

## Notes on Destroy

Before `terraform destroy`, comment out the `prevent_destroy` in `lifecycle` block in `reducto-storage.tf` and `reducto-postgres.tf`

## Troubleshoot

Node pool does not scale up when it can exceed vCPU (regional or family) quotas.

To view status or error message of scale up or scale down activity:

```
kubectl get configmap -n kube-system cluster-autoscaler-status -o yaml
```
