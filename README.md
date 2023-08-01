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

## Kubernetes

### kubeconfig

1. Get kubectl <https://kubernetes.io/docs/tasks/tools/install-kubectl/>
2. Configuration of kubectl <https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/>
3. Test access
   - `--kubeconfig` flag

      ```cmd
      kubectl --kubeconfig kubeconfig get node
      ```

   - `KUBECONFIG` environment variable

      ```cmd
      set KUBECONFIG=kubeconfig
      kubectl get node
      ```

4. Create Kubernetes Dashboard

   ```cmd
   kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml
   kubectl create -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml
   kubectl -n kubernetes-dashboard describe secret admin-user-token
   kubectl proxy
   ```

5. Login Kubernetes Dashboard  
   <http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/>

## Loki

<https://grafana.com/docs/loki/latest/installation/helm/>

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
