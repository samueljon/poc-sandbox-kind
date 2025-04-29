# poc-argocd and crossplane

## Introduction

This is a proof-of-concept installation with kind. The purpose of this POC is to be able to test the basic functionality of ArgoCD and Crossplane on your own laptop.

## How to run

Make sure that you have `kind` installed and underlying container runtime on your laptop. For more details on how to install `kind` see the [official documentation](https://kind.sigs.k8s.io/docs/user/quick-start/)

Go into the cloned directory and execute the following:

```shell
./kind-bootstrap.sh
```

What this will do is install Kubernetes 1.32.2 kind cluster, followed by [olm](https://olm.operatorframework.io/). Once `olm` has been installed a namespace `argocd` will be created were we will install `catalogsource`, `operator group` and a `subscription`. Lastly when these items are installed we create an instance of argocd called `argocd-pod` within the argocd namespace. Lastly we are installing Crossplane V2 Preview.

> Note about the argocd-poc-instance shown below: A role-based-access (RBAC) rules have been added. There are 3 groups defined `cluster-admins`, `argocdadmins` and `argocd-users` where the groups with admin in their names will have argocd admin role whereas argocdusers have readonly permissions. In addition we need to map these groups into `spec.dex.groups` so that we can log in.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: argocd-poc
  labels:
    example: basic
spec:
  rbac:
    defaultPolicy: "role:readonly"
    policy: |
      g, cluster-admins, role:admin
      g, argocdadmins, role:admin
      g, argocdusers, role:readonly
    scopes: "[groups]"
  repo:
    resources:
      limits:
        cpu: "1"
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
  dex:
    openShiftOAuth: false
    groups:
      - argocdusers
      - argocdadmins
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 250m
        memory: 128Mi
```

## How to connect to ArgoCD

Obtaining password for the username `admin`

```shell
kubectl get secret argocd-poc-cluster -n argocd -ojsonpath='{.data.admin\.password}' | base64 -d
```

Accessing the dasboard via port-forwarding

```shell
kubectl port-forward -n argocd service/argocd-poc-server --address=0.0.0.0 58645:443
```

## Crossplane support

Crossplane 2 preview support is also installed in this kind-boostrap.
