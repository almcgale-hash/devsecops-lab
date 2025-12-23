output "web_app_name" {
  value = azurerm_windows_web_app.app.name
}

output "web_app_default_hostname" {
  value = azurerm_windows_web_app.app.default_hostname
}
