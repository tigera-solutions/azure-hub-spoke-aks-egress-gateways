# Azure AKS with Calico CNI: Hub-Spoke VNET & Egress Gateway

## Reference Architecture

![infra](images/hubspoke.png)

## Prerequisites:

First, ensure that you have installed the following tools locally.

1. [azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### Deploy

To provision this example:

#### 1: Deploy Azure Infrastructure

```sh
cd azure
terraform init
terraform apply
```

Enter `yes` at command prompt to apply

#### 2: Deploy Egress Gateways for Calico

```sh
cd egw
terraform init
terraform apply
```

Enter `yes` at command prompt to apply
