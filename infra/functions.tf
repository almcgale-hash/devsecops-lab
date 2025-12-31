# Runtime storage for Function App (ephemeral; OK to destroy daily)
resource "random_string" "func" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "func_runtime" {
  name                     = "stfunc${random_string.func.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
}

resource "azurerm_service_plan" "func" {
  name                = "asp-func-devsecops-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Linux"
  sku_name = "Y1"
}

resource "azurerm_linux_function_app" "ingest" {
  name                = "func-nfl-ingest-${random_string.func.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.func.id

  storage_account_name       = azurerm_storage_account.func_runtime.name
  storage_account_access_key = azurerm_storage_account.func_runtime.primary_access_key

  functions_extension_version = "~4"

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    WEBSITE_RUN_FROM_PACKAGE = "1"

    # Hourly at minute 0 (NCRONTAB)
    TIMER_SCHEDULE = "0 0 */1 * * *"

    # Persistent data lake targets (from infra-data state)
    RAW_CONTAINER        = "raw"
    DATA_STORAGE_ACCOUNT = data.terraform_remote_state.nfl_data.outputs.data_storage_account_name

    # For early smoke testing
    SMOKE_TEST_URL = "https://httpbin.org/json"
  }
}

# RBAC: Function’s managed identity can write blobs to the PERSISTENT storage
resource "azurerm_role_assignment" "func_blob_contrib" {
  scope                = data.terraform_remote_state.nfl_data.outputs.data_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.ingest.identity[0].principal_id
}

output "function_app_name" {
  value = azurerm_linux_function_app.ingest.name
}

output "function_resource_group_name" {
  value = azurerm_resource_group.rg.name
}
