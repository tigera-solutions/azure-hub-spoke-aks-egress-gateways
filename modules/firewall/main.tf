resource "azurerm_public_ip" "pip" {
  name                = var.pip_name
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "fw" {
  name                = var.fw_name
  location            = var.location
  resource_group_name = var.resource_group
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "fw_ip_config"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_log_analytics_workspace" "fw_log_analytics" {
  name                = "${var.fw_name}-log-analytics"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
}

resource "azurerm_monitor_diagnostic_setting" "fwdiag_settings" {
  name               = "${var.fw_name}-settings"
  target_resource_id = azurerm_firewall.fw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.fw_log_analytics.id

  enabled_log {
    category = "AzureFirewallApplicationRule"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [log,metric]
  }
}

# This is the only rule required for successful AKS deployment
resource "azurerm_firewall_application_rule_collection" "allowed_fqdns" {
  name                = "allowed-fqdns"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group
  priority            = 100
  action              = "Allow"

  rule {
    name             = "allow access to fqdn tags"
    source_addresses = ["*"]

    fqdn_tags = [
      "AzureKubernetesService",
    ]
  }

  rule {
    name             = "allow access to public fqdns"
    description      = "allow access to public fqdns"
    source_addresses = ["*"]

    target_fqdns = [
      "auth.docker.io",
      "registry-1.docker.io",
      "production.cloudflare.docker.com",
      "quay.io",
      "*.quay.io",
      "us-docker.pkg.dev",
      "*.projectcalico.org",
      "installer.calicocloud.io",
      "www.calicocloud.io",
      "*.ubuntu.com",
      "*.hcp.${var.location}.azmk8s.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "packages.microsoft.com",
      "acs-mirror.azureedge.net",
      "dc.services.visualstudio.com",
      "*.ods.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.monitoring.azure.com",
    ]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "allowed_network_rules" {
  name                = "allowed-network-rules"
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = var.resource_group
  priority            = 100
  action              = "Allow"

  rule {
    description       = "allow access to apiudp"
    name              = "allow access to apiudp"
    source_addresses  = ["*"]
    destination_ports = ["1194"]
    destination_addresses = ["AzureCloud.${var.location}"]
    protocols         = ["UDP"]
  }

  rule {
    description       = "allow access to apitcp"
    name              = "allow access to apitcp"
    source_addresses  = ["*"]
    destination_ports = ["9000"]
    destination_addresses = ["*"]
    protocols         = ["TCP"]
  }

  rule {
    description       = "allow access to time server"
    name              = "allow access to time server"
    source_addresses  = ["*"]
    destination_ports = ["123"]
    destination_addresses = ["*"]
    protocols         = ["UDP"]
  }

  rule {
    description       = "allow access to azure monitor"
    name              = "allow access to azure monitor"
    source_addresses  = ["*"]
    destination_ports = ["443"]
    destination_addresses = ["AzureMonitor", "Storage"]
    protocols         = ["TCP"]
  }
}
