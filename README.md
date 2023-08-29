# Enabling Workload-Level Security for AKS with Azure Firewall and Calico Egress Gateway

## Reference Architecture

This diagram illustrates our hub-spoke network design and the specific Azure resources used in our reference architecture. Each Spoke VNET shares its Egress Gateway address prefixes with the Azure Route Server located in the Hub VNET, ensuring seamless integration with the Azure network. 

![infra](images/hubspoke.png)

## Prerequisites:

First, ensure that you have installed the following tools locally.

1. [azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### Deploy

To provision this example:

#### 1: Checkout and deploy the Terraform blueprint

```sh
cd azure
terraform init
terraform apply
```

Enter `yes` at command prompt to apply


#### 2: Update your kubeconfig with the AKS cluster credentials

```sh
az aks get-credentials --name spoke1-aks --resource-group spoke-networks --context spoke1-aks
```

#### 3: Verify that Calico is up and running in your AKS cluster

```sh
kubectl get tigerastatus
```

```sh
NAME        AVAILABLE   PROGRESSING   DEGRADED   SINCE
apiserver   True        False         False      9m30s
calico      True        False         False      9m45s
```

#### 2: Deploy Egress Gateways for Calico

```sh
kubectl apply -f manifests
```

OR

```sh
cd egw
terraform init
terraform apply
```

Enter `yes` at command prompt to apply

#### 2: Deploy Egress Gateways for Calico


