output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_container_name" {
  value = azurerm_storage_container.app5_uploads.name
}
