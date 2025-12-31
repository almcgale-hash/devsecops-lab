output "data_resource_group_name" {
  value = azurerm_resource_group.data.name
}

output "data_storage_account_name" {
  value = azurerm_storage_account.data.name
}

output "data_storage_account_id" {
  value = azurerm_storage_account.data.id
}
