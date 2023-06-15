terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.59.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Add Random Integer Resource
resource "random_integer" "ri" {
    min = 10000
    max = 99999
}
  
# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "TaskBoardRG${random_integer.ri.result}"
  location = "West Europe"
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appsp" {
  name                = "taskboard-plan-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "appservice" {
  name                  = "taskboard-${random_integer.ri.result}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_service_plan.appsp.location
  service_plan_id       = azurerm_service_plan.appsp.id
  https_only            = true
  
  site_config { 
    application_stack {
	dotnet_version = "6.0"
	}
	always_on = false
  }
  
  connection_string {
  name = "DefaultConnection"
  type = "SQLAzure"
  value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${azurerm_mssql_server.sqlserver.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

#  Add mssql server and mssql database
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "taskboard-sql${random_integer.ri.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_mssql_database" "sql" {
  name           = "TaskBoardDB${random_integer.ri.result}"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "S0"
  zone_redundant = false
}

#  Add mssql firewall
resource "azurerm_mssql_firewall_rule" "mssql_fw" {
  name             = "TaskBoardFW${random_integer.ri.result}"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

#  Deploy code from a public GitHub repo
resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id             = azurerm_linux_web_app.appservice.id
  repo_url           = "https://github.com/yavorhr/taskboard"
  branch             = "main"
  use_manual_integration = true
 
}
