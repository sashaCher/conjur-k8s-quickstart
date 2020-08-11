#!/bin/bash -e

docker pull cyberark/conjur:latest
docker pull cyberark/conjur-kubernetes-authenticator:latest
docker pull cyberark/conjur-cli:5-latest
docker pull postgres:latest
docker pull nginx:latest

openssl \
     req -newkey rsa:2048 -days "365" -nodes -x509 -config conjur/tls/tls.conf \
     -extensions v3_ca -keyout conjur/tls/nginx.key -out conjur/tls/nginx.cert

cd conjur
./deploy.sh
cd ..
./loadPolicies.sh
cd test-app
docker build -t test-app:latest .
./deploy.sh
cd ..
