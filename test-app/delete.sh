#!/bin/bash

kubectl delete --ignore-not-found deployment test-app
kubectl delete --ignore-not-found configmap conjur-cert
