#!/bin/bash -e

source ../utils.sh

readonly TEST_APP_NAMESPACE_NAME=conjur
readonly CONJUR_NAMESPACE_NAME=conjur

announce "Storing Conjur cert for test app configuration."

ssl_cert=$(cat ../conjur/tls/nginx.cert)

set_namespace $TEST_APP_NAMESPACE_NAME

# Store the Conjur cert in a ConfigMap.
kubectl create configmap conjur-cert --from-file=ssl-certificate=<(echo "$ssl_cert")

echo "Conjur cert stored."

announce "Starting the test app"

kubectl create -f test-app.yaml
