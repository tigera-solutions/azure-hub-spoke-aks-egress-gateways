terraform {
  required_version = ">= 1.2.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.credentials.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.cluster_ca_certificate)
  }
}

data "azurerm_kubernetes_cluster" "credentials" {
  depends_on          = [azurerm_kubernetes_cluster.spoke_1_aks]
  name                = var.spoke_1_cluster_name
  resource_group_name = azurerm_resource_group.spoke.name
}

data "azurerm_kubernetes_service_versions" "current" {
  location       = var.location
  version_prefix = var.kube_version_prefix
}

data "dns_a_record_set" "spoke_1_aks_api_server" {
  depends_on = [azurerm_kubernetes_cluster.spoke_1_aks]
  host       = data.azurerm_kubernetes_cluster.credentials.fqdn
}

resource "azurerm_resource_group" "hub" {
  name     = var.vnet_resource_group_name
  location = var.location
}

resource "azurerm_resource_group" "spoke" {
  name     = var.kube_resource_group_name
  location = var.location
}

module "hub_network" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  vnet_name           = var.hub_vnet_name
  address_space       = ["10.0.0.0/22"]
  subnets = [
    {
      name : "AzureFirewallSubnet"
      address_prefixes : ["10.0.0.0/24"]
    },
    {
      name : "RouteServerSubnet"
      address_prefixes : ["10.0.1.0/24"]
    }
  ]
}

module "spoke_1_network" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  vnet_name           = var.spoke_1_vnet_name
  address_space       = ["10.1.0.0/22"]
  subnets = [
    {
      name : "AKSSubnet"
      address_prefixes : ["10.1.0.0/24"]
    }
  ]
}

module "hub_spoke_1_peering" {
  source                       = "../modules/vnet_peering"
  vnet_1_name                  = var.hub_vnet_name
  vnet_1_id                    = module.hub_network.vnet_id
  vnet_1_rg                    = azurerm_resource_group.hub.name
  vnet_1_allow_gateway_transit = true
  peering_name_1_to_2          = "HubToSpoke1"
  vnet_2_name                  = var.spoke_1_vnet_name
  vnet_2_id                    = module.spoke_1_network.vnet_id
  vnet_2_rg                    = azurerm_resource_group.spoke.name
  vnet_2_use_remote_gateways   = true
  peering_name_2_to_1          = "Spoke1ToHub"

  depends_on = [
    module.hub_route_server,
  ]
}

module "firewall" {
  source         = "../modules/firewall"
  resource_group = azurerm_resource_group.hub.name
  location       = var.location
  pip_name       = "hub-fw-ip"
  fw_name        = "hub-fw"
  subnet_id      = module.hub_network.subnet_ids["AzureFirewallSubnet"]
}

module "spoke_1_routetable" {
  source              = "../modules/route_table"
  resource_group      = azurerm_resource_group.spoke.name
  location            = var.location
  rt_name             = "spoke_1-fw-rt"
  r_name              = "spoke_1-fw-r"
  firewall_private_ip = module.firewall.fw_private_ip
  subnet_id           = module.spoke_1_network.subnet_ids["AKSSubnet"]
}

module "hub_route_server" {
  source         = "../modules/route_server"
  resource_group = azurerm_resource_group.hub.name
  location       = var.location
  subnet_id      = module.hub_network.subnet_ids["RouteServerSubnet"]
  rs_name        = "hub-rs"
  rs_pip_name    = "hub-rs-pip"
  bgp_peers = [
    {
      peer_asn : 63400
      peer_ip : "10.1.0.4"
    },
    {
      peer_asn : 63400
      peer_ip : "10.1.0.5"
    },
  ]
}

resource "azurerm_kubernetes_cluster" "spoke_1_aks" {
  name                    = var.spoke_1_cluster_name
  location                = var.location
  kubernetes_version      = data.azurerm_kubernetes_service_versions.current.latest_version
  resource_group_name     = azurerm_resource_group.spoke.name
  dns_prefix              = "aks"
  private_cluster_enabled = false

  default_node_pool {
    name           = "default"
    node_count     = var.nodepool_nodes_count
    vm_size        = var.nodepool_vm_size
    vnet_subnet_id = module.spoke_1_network.subnet_ids["AKSSubnet"]
    type           = "VirtualMachineScaleSets"
    node_labels = {
      route-reflector = true
    }
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.admin_ssh_key
    }
  }

  network_profile {
    network_plugin = "none"
    service_cidr   = var.network_service_cidr
    dns_service_ip = var.network_dns_service_ip
    outbound_type  = "userDefinedRouting"
  }

  depends_on = [module.spoke_1_routetable, module.firewall, module.hub_spoke_1_peering]
}

resource "azurerm_firewall_network_rule_collection" "spoke_1_apiserver_access" {
  name                = "spoke-1-apiserver-access"
  azure_firewall_name = "hub-fw"
  resource_group_name = azurerm_resource_group.hub.name
  priority            = 105
  action              = "Allow"

  rule {
    description           = "allow access to spoke aks apiserver"
    name                  = "allow access to spoke aks apiserver"
    source_addresses      = ["*"]
    destination_ports     = ["443"]
    destination_addresses = ["${data.dns_a_record_set.spoke_1_aks_api_server.addrs.0}"]
    protocols             = ["TCP"]
  }

  depends_on = [azurerm_kubernetes_cluster.spoke_1_aks]
}

resource "azurerm_firewall_application_rule_collection" "tenant0_allowed_access" {
  name                = "tenant0-allowed-access"
  azure_firewall_name = "hub-fw"
  resource_group_name = azurerm_resource_group.hub.name
  priority            = 110
  action              = "Allow"

  rule {
    name             = "allow access to tenant0 egress gateway"
    description      = "allow access to tenant0 egress gateway"
    source_addresses = ["10.99.0.0/29"]

    target_fqdns = [
      "www.tigera.io",
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

  depends_on = [azurerm_kubernetes_cluster.spoke_1_aks]
}

resource "helm_release" "calico" {
  name             = "calico"
  chart            = "tigera-operator"
  repository       = "https://docs.projectcalico.org/charts"
  version          = var.calico_version
  namespace        = "tigera-operator"
  create_namespace = true
  values = [templatefile("${path.module}/helm_values/values-calico.yaml", {
    pod_cidr     = "${var.pod_cidr}"
    calico_encap = "VXLAN"
  })]

  depends_on = [azurerm_kubernetes_cluster.spoke_1_aks]
}
