# Enabling Workload-Level Security for AKS with Azure Firewall and Calico Egress Gateway

## Solution Overview

In this repo, we'll develop a foundational reference architecture that aligns with the Azure Well-Architected Framework's best practices for network design, with a special emphasis on the hub-spoke network topology. Our goal is to address challenges in pinpointing the source of traffic as it exits the cluster and traverses an external firewall, using Egress Gateways for Calico.

![infra](images/hubspoke.png)

This diagram illustrates our hub-spoke network design and the specific Azure resources used in our reference architecture. Each Spoke VNET shares its Egress Gateway address prefixes with the Azure Route Server located in the Hub VNET, ensuring seamless integration with the Azure network. 

![infra](images/egw-routing.png)

Egress traffic from Kubernetes workloads can be directed through specific Egress Gateways (or none at all), guided by advanced Egress Gateway Policy settings. This configuration creates a distinct network identity suitable for Azure firewall rule settings.

## Prerequisites

First, ensure that you have installed the following tools locally.

1. [azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### Checkout and deploy the Terraform blueprint

#### 1: To provision this example:

Make sure that you completed the prerequisites above and cloned the Terraform blueprint by running the following command in a local directory:

```sh
git clone git@github.com:tigera-solutions/azure-hub-spoke-aks-egress-gateways.git
```

#### 2: Change directory into the azure subdirectory and deploy the infrastructure

```sh
cd azure
terraform init
terraform apply
```

Enter `yes` at command prompt to apply


#### 3: Update your kubeconfig with the AKS cluster credentials

```sh
az aks get-credentials --name spoke1-aks --resource-group spoke-networks --context spoke1-aks
```

#### 4: Verify that Calico is up and running in your AKS cluster

```sh
kubectl get tigerastatus
```

```sh
NAME        AVAILABLE   PROGRESSING   DEGRADED   SINCE
apiserver   True        False         False      9m30s
calico      True        False         False      9m45s
```

### Link your AKS Cluster to Calico Cloud

#### 1: Join the AKS cluster to Calico Cloud

#### 2: Verify your AKS cluster is linked to Calico Cloud

```sh
kubectl get tigerastatus
```

```sh
NAME                            AVAILABLE   PROGRESSING   DEGRADED   SINCE
apiserver                       True        False         False      50m
calico                          True        False         False      49m
cloud-core                      True        False         False      50m
compliance                      True        False         False      49m
image-assurance                 True        False         False      49m
intrusion-detection             True        False         False      49m
log-collector                   True        False         False      50m
management-cluster-connection   True        False         False      49m
monitor                         True        False         False      49m
```

### Deploy Egress Gateways for Calico

#### 1: Peer your AKS cluster to the Azure Route Server

```sh
kubectl apply -f manifests/bgp-route-reflector.yaml
kubectl apply -f manifests/egw-tenants.yaml
kubectl apply -f manifests/egw-policy.yaml
kubectl apply -f manifests/bgp-filter.yaml
```

OR

```sh
cd egw
terraform init
terraform apply
```

Enter `yes` at command prompt to apply

### Validate the Deployment and Review Results

Validate that the Azure Route Server peers are learning routes from the Azure Kubernetes Services cluster the Calico default ippool routes

#### 1: Check the learned routes

```sh
az network routeserver peering list-learned-routes --resource-group hub-network --routeserver hub-rs --name spoke-rs-bgpconnection-peer-1
az network routeserver peering list-learned-routes --resource-group hub-network --routeserver hub-rs --name spoke-rs-bgpconnection-peer-2
```


