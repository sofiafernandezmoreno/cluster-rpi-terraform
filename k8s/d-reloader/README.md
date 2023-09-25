# iscp-d-reloader

`iscp-d-reloader` is based on [Reloader](https://github.com/stakater/Reloader) who can watch changes in ConfigMap and Secret and do rolling upgrades on Pods with their associated DeploymentConfigs, Deployments, Daemonsets Statefulsets and Rollouts.

## Repository structure

```
.
├── CHANGELOG.md
├── CODEOWNERS
├── README.md
├── build
│   └── Dockerfile
├── d-reloader-build.cicd.yaml
├── d-reloader-test.cicd.yaml
├── d-reloader.cicd.yaml
├── k8s
│   ├── d-core-extra-dev-eu-cr-ro.yaml
│   ├── d-reloader
│   │   ├── reloader-clusterrole.yaml
│   │   ├── reloader-clusterrolebinding.yaml
│   │   ├── reloader-deployment.yaml
│   │   └── reloader-serviceaccount.yaml
│   └── ns
│       └── d-reloader-ns.yaml
├── misc
│   └── scripts
│       ├── helm-values-reloader.yaml
│       └── helm2k8s-stekater.sh
└── test
    └── test-reloader.yaml
```
## Container platforms compatibility matrix.

| Component          | Platform                   | Tested versions  |
|:-------------------|:---------------------------|:-----------------|
| "d-reloader"       | Kubernetes Vanilla         | v1.25            |
| "d-reloader"       |Openshift onpremise 4.11    | v1.24            |
| "d-reloader"       |Openshift ROKS 4.12         | v1.24            |
| "d-reloader"       |IKS                         | v1.25            |


### Best practices

* [x] Keep README.md file up to date in all component versions
* [x] Keep CHANGELOG.md file up to date in all component versions
* [x] Keep CODEOWNERS.md file without modifications avoiding insecure controls
* [x] Keep Secrets values and any other sensitive data out of this repo
* [x] Template your "image" attribute in a supported ISCP namespace registry and correct instance  
* [x] Check Naming Convention   
* [x] Check RBAC and objects Permissions  
* [x] Check iscp app labels 
* [x] Check Resource Limits 
* [x] Check AutoScaling, High Availability
* [x] Check Liveness, Readiness and/or service health-checks 
* [x] Document a functional test in a Tool
 
### Default Values vs ISCP Values
```bash
reloader:
  autoReloadAll: false
  isArgoRollouts: false
  isOpenshift: true # k8s will be false
  ignoreSecrets: false
  ignoreConfigMaps: false
  reloadOnCreate: false
  syncAfterRestart: false
  reloadStrategy: default # Set to default, env-vars or annotations
  ignoreNamespaces: "" # Comma separated list of namespaces to ignore
  namespaceSelector: "" # Comma separated list of k8s label selectors for namespaces selection
  resourceLabelSelector: "" # Comma separated list of k8s label selectors for configmap/secret selection
  logFormat: "" #json
  watchGlobally: false
  # Set to true to enable leadership election allowing you to run multiple replicas
  enableHA: false
  # Set to true if you have a pod security policy that enforces readOnlyRootFilesystem
  readOnlyRootFileSystem: false
  legacy:
    rbac: true

Note: By default Reloader watches in all namespaces. To watch in single namespace, please run following command. It will install Reloader in test namespace which will only watch Deployments, Daemonsets Statefulsets and Rollouts in test namespace.
```

### Usage
#### Deployment
* Understand Values and needs
  * By default ISCP installation will watch in a deployed namespace, as addon of your app, however it can be done in a different way based on your needs
  * you can design also workloads annotations to binding with your secrets or doing it automatically
  * review openshift folders for ocp cases
* Fill Variables on `cicd.yaml` file
  - [[ clusterID ]]
  - Enable apply section
* Deploy as usual CICD Method
* Annotate your apps to be used

#### Use Case
[How to use Reloader](https://github.com/stakater/Reloader#how-to-use-reloader)



### Test
* Pods are up and running
* Test your app or deploy `/test` application
  - It contains a `nginx deployment with annotation` + `configmap`
* Modify Configmap
  - Verify workload have been restarted
    ```bash
        > xd cli kubectl -a dev -t tst -p ibc -b 0006 -c k01 -- get pods -n d-reloader
      NAME                                   READY   STATUS    RESTARTS   AGE
      d-reloader-reloader-7479c5f44f-fbfcq   1/1     Running   0          7m45s
      test-reloader-ddf44ccf8-cnf94          1/1     Running   0          13s
      test-reloader-ddf44ccf8-ptk8l          1/1     Running   0          11s
      [@x-term:ibc-dev-tst-0006-k01]$ kubectl logs -n d-reloader d-reloader-reloader-7479c5f44f-fbfcq 
      > xd cli kubectl -a dev -t tst -p ibc -b 0006 -c k01 -- logs -n d-reloader d-reloader-reloader-7479c5f44f-fbfcq
      time="2023-09-19T15:41:06Z" level=info msg="Environment: Kubernetes"
      time="2023-09-19T15:41:06Z" level=info msg="Starting Reloader"
      time="2023-09-19T15:41:06Z" level=warning msg="KUBERNETES_NAMESPACE is unset, will detect changes in all namespaces."
      time="2023-09-19T15:41:06Z" level=info msg="created controller for: configMaps"
      time="2023-09-19T15:41:06Z" level=info msg="Starting Controller to watch resource type: configMaps"
      time="2023-09-19T15:41:06Z" level=info msg="created controller for: secrets"
      time="2023-09-19T15:41:06Z" level=info msg="Starting Controller to watch resource type: secrets"
      time="2023-09-19T15:48:31Z" level=info msg="Changes detected in 'simpleconfig' of type 'CONFIGMAP' in namespace 'd-reloader', Updated 'test-reloader' of type 'Deployment' in namespace 'd-reloader'"
    ```
* Annotations work as expected in your workload
* Deployment is not affected if d-reloader is removed



 ## Upgrade to a new Reloader version

- Create the new version structure.

  ```
  helm repo add stakater https://stakater.github.io/stakater-charts
  cd misc/scripts
  ./helm2k8s-stekater.sh
  ```

- Build new image
  - Enable Build action on `d-reloader-build.cicd.yaml` file
- Review Variables
  - Version ISCP
  - Version Image
  - Version Helm Chart
- Assure images are built