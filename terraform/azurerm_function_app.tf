########################################################################
# *VARIABLES*
########################################################################
variable "fapp_etl_name" {
  type    = string
  default = "python-functionapp"
}

variable "ai_sampling" {
  type = map(number)
  default = {
    Development = 50
    Production  = 100
  }
}

variable "logging_retention" {
  type = map(string)
  default = {
    Development = "1"
    Production  = "3"
  }
}

##################################################################################
# *LOCALS*
##################################################################################
locals {
  fapp_etl_name_env = lower("${var.fapp_etl_name}${var.resource_suffix[terraform.workspace]}")
  secret_uri        = "https://kv-app-${lower(var.env_abbrev[terraform.workspace])}.vault.azure.net/secrets"
}

##################################################################################
# *RESOURCES*
##################################################################################
resource "azurerm_storage_account" "fappstacc" {
  name                     = replace(local.fapp_etl_name_env, "-", "")
  location                 = var.location
  resource_group_name      = local.rg_appsvc
  account_kind             = "Storage"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = local.common_tags
}

resource "azurerm_application_insights" "ai_fapp_etl" {
  name                = local.fapp_etl_name_env
  location            = var.location
  resource_group_name = local.rg_appsvc
  application_type    = "web"
  retention_in_days   = 30
  sampling_percentage = var.ai_sampling[terraform.workspace]

  tags = local.common_tags
}

resource "azurerm_function_app" "fapp_etl" {
  name                       = local.fapp_etl_name_env
  location                   = var.location
  resource_group_name        = local.rg_appsvc
  app_service_plan_id        = data.azurerm_app_service_plan.asp_app.id
  storage_account_name       = azurerm_storage_account.fappstacc.name
  storage_account_access_key = azurerm_storage_account.fappstacc.primary_access_key
  enable_builtin_logging     = false
  https_only                 = true
  os_type                    = "linux"
  version                    = "~3"
  tags                       = local.common_tags

  app_settings = {
    APPCF_ENDPOINT                        = var.appcf_endpoint
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.ai_fapp_etl.connection_string
    ASPNETCORE_ENVIRONMENT                = terraform.workspace
    AZURE_CLIENT_ID                       = var.az_client
    AZURE_CLIENT_SECRET                   = "@Microsoft.KeyVault(SecretUri=${local.secret_uri}/app-svcprinc-appcf)"
    AZURE_TENANT_ID                       = var.az_tenant
    CONTAINER_AVAILABILITY_CHECK_MODE     = "ReportOnly"
    DOCKER_CUSTOM_IMAGE_NAME              = ""
    DOCKER_REGISTRY_SERVER_PASSWORD       = "@Microsoft.KeyVault(SecretUri=${local.secret_uri}/acrapp)"
    DOCKER_REGISTRY_SERVER_URL            = "acrapp.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME       = "acrapp"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
    WEBSITE_HEALTHCHECK_MAXPINGFAILURES   = "10"
    WEBSITE_HTTPLOGGING_RETENTION_DAYS    = var.logging_retention[terraform.workspace]
  }

  site_config {
    always_on                 = true
    ftps_state                = "Disabled"
    health_check_path         = "/api/health"
    linux_fx_version          = ""
    min_tls_version           = "1.2"
    use_32_bit_worker_process = false
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_group_member" "etl_member" {
  group_object_id  = data.azuread_group.app_config.id
  member_object_id = azurerm_function_app.fapp_etl.identity[0].principal_id
}

resource "azurerm_function_app_slot" "fapp_etl" {
  count                      = var.prod_only[terraform.workspace] ? 1 : 0
  name                       = "staging"
  location                   = var.location
  resource_group_name        = local.rg_appsvc
  app_service_plan_id        = data.azurerm_app_service_plan.asp_app.id
  function_app_name          = azurerm_function_app.fapp_etl.name
  storage_account_name       = azurerm_storage_account.fappstacc.name
  storage_account_access_key = azurerm_storage_account.fappstacc.primary_access_key
  enable_builtin_logging     = false
  https_only                 = true
  os_type                    = "linux"
  version                    = "~3"
  tags                       = local.common_tags

  app_settings = {
    APPCF_ENDPOINT                        = var.appcf_endpoint
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.ai_fapp_etl.connection_string
    ASPNETCORE_ENVIRONMENT                = terraform.workspace
    AZURE_CLIENT_ID                       = var.az_client
    AZURE_CLIENT_SECRET                   = "@Microsoft.KeyVault(SecretUri=${local.secret_uri}/app-svcprinc-appcf)"
    AZURE_TENANT_ID                       = var.az_tenant
    CONTAINER_AVAILABILITY_CHECK_MODE     = "ReportOnly"
    DOCKER_CUSTOM_IMAGE_NAME              = ""
    DOCKER_REGISTRY_SERVER_PASSWORD       = "@Microsoft.KeyVault(SecretUri=${local.secret_uri}/acrapp)"
    DOCKER_REGISTRY_SERVER_URL            = "acrapp.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME       = "acrapp"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE   = "false"
    WEBSITE_HEALTHCHECK_MAXPINGFAILURES   = "10"
    WEBSITE_HTTPLOGGING_RETENTION_DAYS    = var.logging_retention[terraform.workspace]
  }

  site_config {
    always_on                 = true
    ftps_state                = "Disabled"
    health_check_path         = "/api/health"
    linux_fx_version          = ""
    min_tls_version           = "1.2"
    use_32_bit_worker_process = false
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_group_member" "etl_slot_member" {
  count            = var.prod_only[terraform.workspace] ? 1 : 0
  group_object_id  = data.azuread_group.app_config.id
  member_object_id = azurerm_function_app_slot.fapp_etl[0].identity[0].principal_id
}

resource "azurerm_monitor_metric_alert" "fapp" {
  count               = var.prod_only[terraform.workspace] ? 2 : 0
  name                = replace("${var.metric_ns} ${var.monitor_set_str["MetricName"][count.index]} ${azurerm_function_app.fapp_etl.name}", "/", ".")
  resource_group_name = local.rg_appsvc
  scopes              = [azurerm_function_app.fapp_etl.id]
  tags                = local.common_tags
  enabled             = true
  auto_mitigate       = true
  frequency           = var.monitor_set_str["Frequency"][count.index]
  window_size         = var.monitor_set_str["WindowSize"][count.index]
  severity            = var.monitor_set_num["Severity"][count.index]
  criteria {
    metric_namespace = var.metric_ns
    metric_name      = var.monitor_set_str["MetricName"][count.index]
    aggregation      = var.monitor_set_str["Aggregation"][count.index]
    operator         = "GreaterThan"
    threshold        = var.monitor_set_num["Threshold"][count.index]

  }

  action {
    action_group_id = data.azurerm_monitor_action_group.agapp.id
  }
}

##################################################################################
# *OUTPUT*
##################################################################################
output "fappstacc_out" {
  value = azurerm_storage_account.fappstacc.name
}
output "ai_fapp_etl_out" {
  value = azurerm_application_insights.ai_fapp_etl.name
}
output "fapp_etl_out" {
  value = azurerm_function_app.fapp_etl.name
}
