#!/bin/bash -e

source ../utils.sh

# Constants
readonly CONJUR_NAMESPACE_NAME=conjur
readonly CONJUR_SERVICEACCOUNT_NAME=conjur
readonly CONJUR_ACCOUNT=myorg

# Make sure we are in the Conjur namespace scope
announce "Creating $CONJUR_NAMESPACE_NAME namespace."
set_namespace default

if has_namespace "$CONJUR_NAMESPACE_NAME"; then
  echo "Namespace '$CONJUR_NAMESPACE_NAME' exists, not going to create it."
  set_namespace $CONJUR_NAMESPACE_NAME
else
  echo "Creating '$CONJUR_NAMESPACE_NAME' namespace."
  kubectl create namespace $CONJUR_NAMESPACE_NAME

  set_namespace $CONJUR_NAMESPACE_NAME
fi

if ! has_serviceaccount $CONJUR_SERVICEACCOUNT_NAME; then
  echo "Creating '$CONJUR_SERVICEACCOUNT_NAME' service account in namespace $CONJUR_NAMESPACE_NAME"
  kubectl create serviceaccount $CONJUR_SERVICEACCOUNT_NAME -n $CONJUR_NAMESPACE_NAME
fi

kubectl create -f conjur-authenticator-role.yaml
kubectl create -f conjur-local-role.yaml
kubectl create -f conjur-local-role-binding.yaml
kubectl create -f conjur-authenticator-role-binding.yaml

set_namespace $CONJUR_NAMESPACE_NAME

announce "Creating secrets and configmaps"

docker run --rm cyberark/conjur data-key generate > data.key
kubectl create secret generic conjur-data-key --from-file=data.key
kubectl create secret generic nginx-certs-keys --from-file=./tls/nginx.cert --from-file=./tls/nginx.key
kubectl create configmap nginx-configmap --from-file=./nginx/default.conf

announce "Deploying Conjur"

kubectl create -f conjur.yaml

echo "Waiting for Conjur pod to launch..."
wait_for_it 300 "kubectl describe pod conjur | grep State: | grep -c Running | grep -q 3"

echo "Conjur created."
conjur_pod=$(kubectl get pods | grep conjur | cut -f 1 -d ' ')

announce "Deploying Conjur CLI pod."

kubectl create -f conjur-cli.yaml

echo "Waiting for Conjur CLI pod to launch..."
wait_for_it 300 "kubectl describe po conjur-cli | grep State: | grep -c Running | grep -q 1"

# Setup Conjur
conjur_cli_pod=$(kubectl get pods | grep conjur-cli | cut -f 1 -d ' ')
echo -n "Waiting for Conjur deployment ready"
while : ; do
  code=$(kubectl exec $conjur_cli_pod -- curl -sLk -w "%{http_code}\\n" https://conjur-cluster -o /dev/null 2>/dev/null ) || true
  if [ $code -eq "200" ]; then
    break
  fi
  echo -n "."
  sleep 10
done
echo

announce "Creating admin account."

conjur_admin_api_key=$(kubectl exec $conjur_pod -c conjur -- conjurctl account create $CONJUR_ACCOUNT | grep "API key for admin" | cut -f 5 -d ' ')
echo "admin API key is $conjur_admin_api_key"

# Setup Conjur CLI
announce "Initilalizing Conjur CLI container"

kubectl exec $conjur_cli_pod -- bash -c "yes yes | conjur init -a $CONJUR_ACCOUNT -u https://conjur-cluster"
kubectl exec $conjur_cli_pod -- conjur authn login -u admin -p $conjur_admin_api_key

announce "Done"
