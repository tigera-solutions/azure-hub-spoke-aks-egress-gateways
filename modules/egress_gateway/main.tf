resource "kubernetes_manifest" "ippool_tenant0_pool" {
  manifest = {
    "apiVersion" = "projectcalico.org/v3"
    "kind"       = "IPPool"
    "metadata" = {
      "name" = "tenant0-pool"
    }
    "spec" = {
      "blockSize"    = 31
      "cidr"         = "10.99.0.0/29"
      "nodeSelector" = "!all()"
      "vxlanMode"    = "Never"
    }
  }
}

resource "kubernetes_manifest" "egressgateway_tenant0_tenant0_egw" {
  manifest = {
    "apiVersion" = "operator.tigera.io/v1"
    "kind"       = "EgressGateway"
    "metadata" = {
      "name"      = "tenant0-egw"
      "namespace" = "tenant0"
    }
    "spec" = {
      "ipPools" = [
        {
          "name" = "tenant0-pool"
        },
      ]
      "logSeverity" = "Info"
      "replicas"    = 2
      "template" = {
        "metadata" = {
          "labels" = {
            "tenant" = "tenant0"
          }
        }
        "spec" = {
          "nodeSelector" = {
            "kubernetes.io/os" = "linux"
          }
          "terminationGracePeriodSeconds" = 0
          "topologySpreadConstraints" = [
            {
              "labelSelector" = {
                "matchLabels" = {
                  "tenant" = "tenant0"
                }
              }
              "maxSkew"           = 1
              "topologyKey"       = "topology.kubernetes.io/zone"
              "whenUnsatisfiable" = "DoNotSchedule"
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "bgpfilter_export_egress_ips" {
  manifest = {
    "apiVersion" = "projectcalico.org/v3"
    "kind"       = "BGPFilter"
    "metadata" = {
      "name" = "export-egress-ips"
    }
    "spec" = {
      "exportV4" = [
        {
          "action"        = "Reject"
          "cidr"          = "10.99.0.0/29"
          "matchOperator" = "NotIn"
        },
        {
          "action"        = "Reject"
          "cidr"          = "10.99.0.8/29"
          "matchOperator" = "NotIn"
        },
      ]
    }
  }
}
