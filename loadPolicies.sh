#!/bin/bash -e

source ./utils.sh

conjur_cli_pod=$(kubectl get pods | grep conjur-cli | cut -f 1 -d ' ')

load_policy_k8s ./policies/01-root.yml root "conjur/$conjur_cli_pod"
load_policy_k8s ./policies/02-conjur.yml conjur "conjur/$conjur_cli_pod"
load_policy_k8s ./policies/03-authn-k8s-prod.yml conjur/authn-k8s/prod "conjur/$conjur_cli_pod"

echo "Generating authn-k8s certificate and loading it to the variables..."
./generateCertiticate.sh
kubectl exec $conjur_cli_pod -- conjur variable values add conjur/authn-k8s/prod/ca/key "$(cat k8s.key)"
kubectl exec $conjur_cli_pod -- conjur variable values add conjur/authn-k8s/prod/ca/cert "$(cat k8s.cert)"

echo -n "Enabling authn-k8s/prod authenticator... "
token=$(kubectl exec $conjur_cli_pod -- conjur authn authenticate -H)
kubectl exec $conjur_cli_pod -- curl -s -w "%{http_code}\n" --cacert /root/conjur-myorg.pem --request PATCH --data "enabled=true" -H "$token" 'https://conjur-cluster/authn-k8s/prod/myorg'

load_policy_k8s ./policies/04-authn-k8s-prod-apps.yml conjur/authn-k8s/prod/apps "conjur/$conjur_cli_pod"
load_policy_k8s ./policies/05-secrets.yml secrets "conjur/$conjur_cli_pod"

echo "Loading Secret's variables values..."
kubectl exec $conjur_cli_pod -- conjur variable values add secrets/db/password "$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
kubectl exec $conjur_cli_pod -- conjur variable values add secrets/db/username "$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
kubectl exec $conjur_cli_pod -- conjur variable values add secrets/db/address "$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

load_policy_k8s ./policies/06-secrets-consumers.yml secrets/consumers "conjur/$conjur_cli_pod"
