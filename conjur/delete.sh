#!/bin/bash -e

source ../utils.sh

# Constants
readonly CONJUR_NAMESPACE_NAME=conjur
readonly CONJUR_SERVICEACCOUNT_NAME=conjur

kubectl delete --ignore-not-found service conjur-cluster
kubectl delete --ignore-not-found deployment conjur-cli
kubectl delete --ignore-not-found deployment conjur
kubectl delete --ignore-not-found serviceaccount $CONJUR_SERVICEACCOUNT_NAME
kubectl delete --ignore-not-found clusterrole conjur-authenticator-conjur
kubectl delete --ignore-not-found role secrets-reader
kubectl delete --ignore-not-found rolebinding secrets-reader
kubectl delete --ignore-not-found rolebinding test-app-conjur-authenticator-role-binding-$CONJUR_NAMESPACE_NAME
kubectl delete --ignore-not-found rolebinding conjur-authenticator-role-binding-$CONJUR_NAMESPACE_NAME
kubectl delete --ignore-not-found secret nginx-certs-keys
kubectl delete --ignore-not-found secret conjur-data-key
kubectl delete --ignore-not-found configmap nginx-configmap
