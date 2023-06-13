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
  name     = "ContactBookRG${random_integer.ri.result}"
  location = "West Europe"
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appsp" {
  name                = "contact-book-plan-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "appservice" {
  name                  = "contact-book-${random_integer.ri.result}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_service_plan.appsp.location
  service_plan_id       = azurerm_service_plan.appsp.id
  https_only            = true
  
  site_config { 
    application_stack {
	node_version = "16-lts"
	}
	always_on = false
  }
}

#  Deploy code from a public GitHub repo
resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id             = azurerm_linux_web_app.appservice.id
  repo_url           = "https://github.com/nakov/ContactBook"
  branch             = "master"
  use_manual_integration = true
 
}
