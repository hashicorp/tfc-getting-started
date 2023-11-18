terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.67.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "ec9bd257-7c8e-4a6f-9f02-a5ace6c343ac"
  features {}
}

//resource "azurerm_resource_group" "Smitha_RG" {
//  name     = "Smitha_RG"
//  location = "CentralIndia"
//}
//resource "azurerm_resource_group" "Meghna_RG" {
//  name     = "Meghna_RG"
//  location = "CentralIndia"
//}



