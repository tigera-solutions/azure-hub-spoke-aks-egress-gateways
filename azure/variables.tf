variable "location" {
  description = "The resource group location"
  default     = "eastus"
}

variable "vnet_resource_group_name" {
  description = "The resource group name to be created"
  default     = "demo-hub-network"
}

variable "kube_resource_group_name" {
  description = "The resource group name to be created"
  default     = "demo-spoke-networks"
}

variable "admin_username" {
  description = "Admin username"
  default     = "azureuser"
}

variable "admin_ssh_key" {
  description = "Admin SSH public key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsi+rMbWujrAJbRyee4wLwB7qWVG3VzZdSj3xlfdnZaMp2PBKjhryAljF9jwVuzQKsNDjkWfxGEmCsUJ9GU0m9PSrLZC78etd3FivEnihZumAlUzkGDq+WgMqOyWPhfCikNqldlnkS4BB0IdwNej8RuDj6OEzvyJDvfGzjBtj6sR2hAaUM7KBh6MCu/BXOsbKF+/A5LwaZylDD1kBjXqEdLth9qgw11SyO2b5na3HHu2a13jOPbCuqKTKzvmxIadb1Eo/eV8sq/AnjmPK4y0qOD6KyqsOEpPjlqIbH7FJIL0nhRcaKVfD1HNKLlSmOWKSG8cimmJimBgw84OPIAc0v demo@example.com"
}

variable "hub_vnet_name" {
  description = "Hub VNET name"
  default     = "hub-vnet"
}

variable "spoke_1_vnet_name" {
  description = "Spoke1 VNET name"
  default     = "spoke1-vnet"
}

variable "spoke_1_cluster_name" {
  description = "Spoke1 AKS cluster name"
  default     = "spoke1-aks"
}

variable "kube_version_prefix" {
  description = "AKS Kubernetes version prefix. Formatted '[Major].[Minor]' like '1.18'. Patch version part (as in '[Major].[Minor].[Patch]') will be set to latest automatically."
  default     = "1.26"
}

variable "nodepool_nodes_count" {
  description = "Default nodepool nodes count"
  default     = 2
}

variable "nodepool_vm_size" {
  description = "Default nodepool VM size"
  default     = "Standard_D2_v2"
}

variable "network_dns_service_ip" {
  description = "CNI DNS service IP"
  default     = "10.9.0.10"
}

variable "network_service_cidr" {
  description = "CNI service cidr"
  default     = "10.9.0.0/24"
}

variable "pod_cidr" {
  description = "Calico POD CIDR"
  type        = string
  default     = "10.244.0.0/24"
}

variable "calico_version" {
  description = "Calico Open Source release version"
  type        = string
  default     = "3.25.1"
}
