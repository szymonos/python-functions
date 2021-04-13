terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.55.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>1.4.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "RG-InfraStructure-Prod"
    storage_account_name = "appsadevops"
    container_name       = "terraform-state"
    key                  = "pyfapp.tfstate"
    subscription_id      = "00000000-0000-0000-0000-00000000PROD" # Prod
  }
}

########################################################################
# *VARIABLES*
########################################################################
variable "az_tenant" {
  type    = string
  default = "00000000-0000-0000-0000-000000TENANT"
}

variable "az_subscription" {
  type = map(string)
  default = {
    Development = "00000000-0000-0000-0000-000000000DEV" # DEV
    Production  = "00000000-0000-0000-0000-00000000PROD" # Prod
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "env_abbrev" {
  type = map(string)
  default = {
    Development = "Dev"
    Production  = "Prod"
  }
}

variable "resource_suffix" {
  type = map(string)
  default = {
    Development = "-dev"
    Production  = ""
  }
}

variable "prod_only" {
  type = map(bool)
  default = {
    Development = false
    Production  = true
  }
}

##################################################################################
# *PROVIDERS*
##################################################################################
provider "azurerm" {
  subscription_id = var.az_subscription[terraform.workspace]
  features {}
}

provider "azuread" {
}

##################################################################################
# *LOCALS*
##################################################################################
locals {
  common_tags = {
    ENV = upper(var.env_abbrev[terraform.workspace])
  }
}
