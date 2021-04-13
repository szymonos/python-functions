########################################################################
# *VARIABLES*
########################################################################
variable "appcf_endpoint" {
  type    = string
  default = "https://app-appcf.azconfig.io"
}

variable "az_client" {
  type    = string
  default = "00000000-0000-0000-0000-000000CLIENT"
}

variable "rg_appsvc_name" {
  type    = string
  default = "RG-AppSvc"
}

variable "asp_name" {
  type    = string
  default = "asp-app"
}

variable "branch_name" {
  type = map(string)
  default = {
    Development = "dev"
    Production  = "main"
  }
}

variable "metric_ns" {
  type    = string
  default = "Microsoft.Web/sites"
}

variable "monitor_set_str" {
  type = map(list(string))
  default = {
    MetricName  = ["Http5xx", "Http403"]
    Aggregation = ["Count", "Count"]
    Frequency   = ["PT1M", "PT1M"]
    WindowSize  = ["PT5M", "PT5M"]
  }
}

variable "monitor_set_num" {
  type = map(list(number))
  default = {
    Threshold = [0, 0]
    Severity  = [0, 3]
  }
}

##################################################################################
# *LOCALS*
##################################################################################
locals {
  rg_appsvc    = "${var.rg_appsvc_name}-${var.env_abbrev[terraform.workspace]}"
}

##################################################################################
# *DATA*
##################################################################################
data "azurerm_app_service_plan" "asp_app" {
  resource_group_name = local.rg_appsvc
  name                = "${var.asp_name}${var.resource_suffix[terraform.workspace]}"
}

data "azuread_group" "app_config" {
  display_name = "App-AppConfig-${var.env_abbrev[terraform.workspace]}"
}

data "azurerm_monitor_action_group" "agapp" {
  resource_group_name = "RG-DevOps-${var.env_abbrev[terraform.workspace]}"
  name                = "ag-app${var.resource_suffix[terraform.workspace]}"
}
