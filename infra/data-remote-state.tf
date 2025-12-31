data "terraform_remote_state" "nfl_data" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateal12346"
    container_name       = "tfstate"
    key                  = "nfl-data.tfstate"
  }
}
