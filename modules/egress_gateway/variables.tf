variable "cluster_as_number" {
  description = "AKS Cluster BGP AS Number"
  type        = string
}

variable "cluster_next_hop_ip" {
  description = "AKS cluster next hop ip"
  type        = string
}

variable "route_server_as_number" {
  description = "Azure Route Server AS Number"
  type        = string
}

variable "route_server_bgppeer_a_ip" {
  description = "Azure Route Server peer a IP address"
  type        = string
}

variable "route_server_bgppeer_b_ip" {
  description = "Azure Route Server peer b IP address"
  type        = string
}
