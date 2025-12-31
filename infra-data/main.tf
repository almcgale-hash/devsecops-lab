resource "random_string" "data" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "data" {
  name     = "rg-nfl-data"
  location = "canadacentral"
}

resource "azurerm_storage_account" "data" {
  name                     = "stnfl${random_string.data.result}"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "raw" {
  name                  = "raw"
  storage_account_name  = azurerm_storage_account.data.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "curated" {
  name                  = "curated"
  storage_account_name  = azurerm_storage_account.data.name
  container_access_type = "private"
}
