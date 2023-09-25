# Raspberry Pi Initialization with Terraform

This is for Provisioning a Rpi 3 and 4 K3s cluster using terraform.

## Manual Steps

### Raspberry

Burn image to sd card.

Inject file `/boot/ssh` to autostart ssh. <https://www.raspberrypi.org/documentation/remote-access/ssh/README.md>

### terraform.tfvars

Create a file `terraform.tfvars` for easy adding variable defaults.
An Example File `terraform.example.tfvars` is included.

## Deployment

My cluster has the following components:

  Name         | Ram  | IP Address    | Hostname  | Role   |
---------------|------|---------------|-----------|--------|
Raspberry Pi 4 | 4 GB | 192.168.0.28  | rpi01     | Master |
Raspberry Pi 3 | 1 GB | 192.168.0.4   | rpi02     | Worker |
Raspberry Pi 3 | 1 GB | 192.168.0.5   | rpi03     | Worker |

### Servernode

```cmd
terraform workspace new rpi01
terraform workspace select rpi01
terraform init
terraform plan -var-file="terraform.rpi01.tfvars"
terraform apply -var-file="terraform.rpi01.tfvars"
```

### Workernode

```cmd
terraform workspace new rpi02
terraform workspace select rpi02
terraform init
terraform plan -var-file="terraform.rpi02.tfvars"
terraform apply -var-file="terraform.rpi02.tfvars"
```

```cmd
terraform workspace new rpi03
terraform workspace select rpi03
terraform init
terraform plan -var-file="terraform.rpi03.tfvars"
terraform apply -var-file="terraform.rpi03.tfvars"
```



## [Loki](https://grafana.com/docs/loki/latest/installation/helm/>)

```sh
helm repo add loki https://grafana.github.io/loki/charts
helm repo update
helm upgrade --install loki --namespace=loki --create-namespace loki/loki-stack  --set grafana.enabled=true,prometheus.enabled=true,prometheus.alertmanager.persistentVolume.enabled=false,prometheus.server.persistentVolume.enabled=false
```

### Loki Grafana

```sh
kubectl get secret --namespace loki loki-grafana -o jsonpath="{.data.admin-password}"
kubectl port-forward --namespace loki service/loki-grafana 3000:80
```

Navigate to <http://localhost:3000> and login with `admin` and the password output above. Then follow the instructions for adding the Loki Data Source, using the URL <http://loki:3100/> for Loki.

## Install Prometheus and Grafana using Helm

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install prometheus --namespace monitoring --debug --values kube-prometheus-stack.values.yml prometheus-community/kube-prometheus-stack
```


## [Vault](https://github.com/hashicorp/vault-helm)

When vault is on 0/1 is important [unseal](https://developer.hashicorp.com/vault/docs/concepts/seal) the process.

```
kubectl -n vault exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > vault-cluster-keys.json

kubectl -n vault exec vault-0 -- vault operator unseal G02+XD9M1z300sTCdgNCnyBPyvo+90mfY87L8cUoSig=


kubectl port-forward -n vault vault-0 8200:8200
```

```
WARNING! dev mode is enabled! In this mode, Vault runs entirely in-memory
and starts unsealed with a single unseal key. The root token is already
authenticated to the CLI, so you can immediately begin using Vault.

You may need to set the following environment variables:

    $ export VAULT_ADDR='http://[::]:8200'

The unseal key and root token are displayed below in case you want to
seal/unseal the Vault or re-authenticate.

Unseal Key: VXqjKDQ8YQtRbH2HDgXvMYi6j1g55/VwTMj03WQujRw=
Root Token: root

Development mode should NOT be used in production installations!


```
