#!/bin/bash -e

SERVICE_ID="prod"
CONJUR_ACCOUNT="myorg"

# Generate OpenSSL private key
openssl genrsa -out k8s.key 2048

CONFIG="
[ req ]
distinguished_name = dn
x509_extensions = v3_ca
[ dn ]
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
"

# Generate root CA certificate
openssl req -x509 -new -nodes -key k8s.key -sha1 -days 3650 -set_serial 0x0 -out k8s.cert \
  -subj "/CN=conjur.authn-k8s.$SERVICE_ID/OU=Conjur Kubernetes CA/O=$CONJUR_ACCOUNT" \
  -config <(echo "$CONFIG")

# Verify cert
openssl x509 -in k8s.cert -text -noout
