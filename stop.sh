#!/bin/bash -e

source ./utils.sh

cd test-app
./delete.sh
cd ..
cd conjur
./delete.sh
cd ..

wait_for_it 300 "kubectl get pods 2>&1 | grep -q 'No resources found in'"
