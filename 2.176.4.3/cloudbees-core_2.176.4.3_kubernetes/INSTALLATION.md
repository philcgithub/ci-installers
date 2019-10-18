# CloudBees Core Installation

## Prerequisites

* A running Kubernetes v1.10+/OpenShift v3.7+ cluster
  *  For each CPU Core, a gigabyte of available memory is required.
        * For example, a node with two CPUs cores requires four Gbs of memory
* CloudBees Core uses the [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx/blob/master/deploy/README.md). The installation can use an existing nginx controller, or it can be installed during the CloudBees Core installation.
  * NGINX Ingress Controller is not required for OpenShift
* A namespace in the cluster (provided by your admin) with permissions to create `Role` and `RoleBinding` objects
  * Typically this means `cluster-admin` (full) permission in that namespace, and that namespace only.
  * Only needed during installation, services will run using the created roles with limited privileges.
* A [default `storageclass`](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/) configured
  * `kubectl get sc -o yaml | grep storageclass.beta.kubernetes.io/is-default-class` should return something
* A DNS record pointing to your ingress controller load balancer or ip
* Helm/Tiller installed on the desired cluster.

## Preparation

Switch to the namespace where CloudBees Core will be installed (provided by your kubernetes admin) if not using it already

    NAMESPACE=core
    kubectl config set-context $(kubectl config current-context) --namespace=${NAMESPACE}


### OpenShift

If using OpenShift replace occurrences of `namespace: myproject` with the actual name
of the project where CloudBees Core is installed.

NOTE: If using the web UI _Import YAML_ option to import the definition file you may need
to run the import twice as Role and RoleBinding definitions are not created on the same import.

## Installation
CloudBees Core for Modern Platform has two installation methods.
CloudBees recommended installing CloudBees Core using the Helm Package Manager.
CloudBees also provides a YAML file-based installation process.

### Helm Package installation
In this installation bundle, the `helm-chart` directory contains a compressed Helm Chart Package. 
The Helm Chart includes a [Markdown](https://www.markdownguide.org/) for README.md file the explains installing CloudBees Core for Modern Platforms using Helm. 
CloudBees also provides full documenation on the Helm installation process on our website at [Installing CloudBees Core using our Helm Chart](https://go.cloudbees.com/docs/cloudbees-core/cloud-install-guide/kubernetes-helm-install/)

The following Helm command will out put the README.md file:

```console
$ helm inspect readme cloudbees-core.tgz
```

For additional installation information and configuration parameters, please consult the install CloudBees Core with     

### YAML file-based installation
Create Operations Center (aka CJOC) and other services and configurations

    kubectl create -f cloudbees-core.yml

In order to check that all resources are created, the following command can be run

    kubectl get pod,svc,statefulset,ingress,pvc,role,rolebinding

## Updating

If changes are made to the installation file, they can be applied again with

    kubectl apply -f cloudbees-core.yml


## Configure Operations Center

Operations Center (aka CJOC) can be accessed with the following URL (replace `cloudbees-core.example.com` by your domain name):

     https://cloudbees-core.example.com/cjoc

Check that the Operations Center pod is running with

    kubectl describe pod/cjoc-0

You can always check the Operations Center logs with

    kubectl logs -f cjoc-0

After allowing some time for Operations Center to start, then get the Operations Center initial password with

    kubectl exec cjoc-0 -- cat /var/jenkins_home/secrets/initialAdminPassword

If there is no output it means the pod is not yet started, you can check messages from
kubernetes with

    kubectl describe pod/cjoc-0

or

    kubectl get events --watch

## Create a new Master

You can spin up a new Master in the same way as with CloudBees Jenkins Enterprise 1.x (aka CJE 1.x.).
The new Master (named master1) is accessible using the URL (replace by your domain name):

    http://cloudbees-core.example.com/master1

## Setup a Pipeline using a Node running inside Kubernetes

Declare a simple Pipeline with the following code:

     podTemplate(label: 'kubernetes',
                 containers: [
                 containerTemplate(name: 'maven', image: 'maven:3.5.2-jdk-8-alpine', ttyEnabled: true, command: 'cat')
                 ]) {
         stage('Dummy') {
             node('kubernetes') {
                 container('maven') {
                     sh 'mvn --version'
                 }
             }
         }
     }

### Connecting External Masters

If there is a need to connect external masters, run

    kubectl create -f cjoc-external-masters.yml

This Service will open the Operations Center remoting jnlp port in **all nodes** in the cluster.

Get the Operations Center port that is exposed with

    kubectl get svc/cjoc-jnlp -o jsonpath='{.spec.ports[0].nodePort}'

Security groups in nodes need to be opened or an ELB setup to connect from the external
master into this port.


## Upgrading

To upgrade CloudBees Core including all Kubernetes objects, reapply the latest version of `cloudbees-core.yml`, including the changes mentioned
above for new installations (domain name, SSL,...).

    kubectl apply -f cloudbees-core.yml

### Upgrading Operations Center Only

This should be performed if and only if the only change is Operations Center and Master Docker image versions.

Update the Operations Center image, the pod will be killed and a new one using the new image is started.
You can get the new version from the `cloudbees-core.yml` file included in the new Operations Center release.

    kubectl patch statefulset cjoc -p '{"spec":{"template":{"spec":{"containers":[{"name":"jenkins","image":"cloudbees/cloudbees-cloud-core-oc:NEW_VERSION"}]}}}}'


# Teardown

Stopping Operations Center

    kubectl scale statefulsets/cjoc --replicas=0

Delete the services, pods, ingress

    kubectl delete -f cloudbees-core.yml

Delete remaining pods, data

    kubectl delete pod,statefulset,pvc,ingress,service -l com.cloudbees.cje.tenant

Delete everything else, including started masters and all data in the namespace!!!

    kubectl delete svc --all
    kubectl delete statefulset --all
    kubectl delete pod --all
    kubectl delete ingress --all
    kubectl delete pvc --all
