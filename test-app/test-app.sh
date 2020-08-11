#!/bin/bash

ACCT=myorg

echo "Fetching username and password"

while true
do
  token=$(cat "/run/conjur/access-token" | base64 | tr -d '\r\n')

  if [ "$token" = "" ]; then
    echo "Token not created yet"
  else
    curl -s --cacert /opt/conjur_cert/ssl-certificate -H "Authorization: Token token=\"$token\"" https://conjur-cluster/resources/$ACCT | jq .
    response=$(curl -s --cacert /opt/conjur_cert/ssl-certificate -H "Authorization: Token token=\"$token\"" https://conjur-cluster/secrets/$ACCT/variable/secrets/db/address)
    echo "Address: $response"
    response=$(curl -s --cacert /opt/conjur_cert/ssl-certificate -H "Authorization: Token token=\"$token\"" https://conjur-cluster/secrets/$ACCT/variable/secrets/db/username)
    echo "Username: $response"
    response=$(curl -s --cacert /opt/conjur_cert/ssl-certificate -H "Authorization: Token token=\"$token\"" https://conjur-cluster/secrets/$ACCT/variable/secrets/db/password)
    echo "Password: $response"
  fi

  sleep 10
done
