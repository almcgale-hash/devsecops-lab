resource "azurerm_resource_group" "rg" {
  name     = "rg-devsecops-lab"
  location = "canadacentral"
}
# PR test change - triggers terraform plan

resource "azurerm_service_plan" "plan" {
  name                = "asp-devsecops-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Windows"
  sku_name = "F1" # Free tier if available
}

resource "azurerm_windows_web_app" "app" {
  name                = "devsecops-lab-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = false
  }
}
 
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
