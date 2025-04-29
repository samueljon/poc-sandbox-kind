#!/bin/bash

export BASE_HOST=127.0.0.1.nip.io

echo "------------------------------------------------------"
echo "Creating cluster at $(date +"%T")"
echo "------------------------------------------------------"

kind create cluster --config kind.yaml

echo "------------------------------------------------------"
echo "Waiting for 15 seconds cluster to be ready before we continue"
echo "------------------------------------------------------"
sleep 15

echo "------------------------------------------------------"
echo "Waiting for api-server pod at $(date +"%T")"
echo "------------------------------------------------------"

kubectl wait --namespace kube-system --for=condition=ready pod --selector=component=kube-apiserver --timeout=120s

echo "------------------------------------------------------"
echo "Waiting for controller-manager pod at $(date +"%T")"
echo "------------------------------------------------------"

kubectl wait --namespace kube-system --for=condition=ready pod --selector=component=kube-controller-manager --timeout=120s

echo "------------------------------------------------------"
echo "Waiting for core-dns pod at $(date +"%T")"
echo "------------------------------------------------------"

kubectl wait --namespace kube-system --for=condition=ready pod --selector=k8s-app=kube-dns --timeout=120s

echo "------------------------------------------------------"
echo "Installing Nginx Ingress to ingress-nginx namespace at $(date +"%T")"
echo "------------------------------------------------------"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

echo "------------------------------------------------------"
echo "Install the Operator Lifecycle Manager (OLM) at $(date +"%T")"
echo "------------------------------------------------------"

curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.31.0/install.sh | bash -s v0.31.0

echo "------------------------------------------------------"
echo "Creating argocd namespace at $(date +"%T")"
echo "------------------------------------------------------"

kubectl create namespace argocd

echo "------------------------------------------------------"
echo "Installing ArgoCD resources at $(date +"%T")"
echo "------------------------------------------------------"
kubectl create -n olm -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/refs/heads/master/deploy/catalog_source.yaml
kubectl get catalogsources -n olm
kubectl get pods -n olm -l olm.catalogSource=argocd-catalog
sleep 20

kubectl create -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/refs/heads/master/deploy/operator_group.yaml
echo "=== Get Operator Groups"
kubectl get operatorgroups -n argocd
sleep 20

kubectl create -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-operator/refs/heads/master/deploy/subscription.yaml
sleep 20
echo "=== Get Operator Groups"
kubectl get subscriptions -n argocd
sleep 20
echo "=== Get Install Plans"
kubectl get installplans -n argocd
sleep 20
echo "=== Get ArgoCD pods"
kubectl get pods -n argocd

echo "------------------------------------------------------"
echo "Waiting for ArgoCD Controller Manager to become available at $(date +"%T")"
echo "------------------------------------------------------"

kubectl wait --namespace argocd deployment.apps/argocd-operator-controller-manager --for condition=Available=True --timeout=90s

echo "------------------------------------------------------"
echo "Creating ArgoCD instance at $(date +"%T")"
echo "------------------------------------------------------"

kubectl create -n argocd -f deploy/argocd-poc-instance.yaml

echo "------------------------------------------------------"
echo "Installing Crossplane helm chart at $(date +"%T")"
echo "------------------------------------------------------"

#helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo add crossplane-preview https://charts.crossplane.io/preview
helm repo update

#helm upgrade --install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace --wait
helm install crossplane \
--namespace crossplane-system \
--create-namespace crossplane-preview/crossplane \
--version v2.0.0-preview.1 --wait

echo "------------------------------------------------------"
echo "Initial setup finished at $(date +"%T")"
echo "------------------------------------------------------"
