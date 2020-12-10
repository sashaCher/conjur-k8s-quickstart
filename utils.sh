#!/bin/bash

announce() {
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo ""
  printf "$@\n"
  echo ""
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

function load_policy_k8s() {
  filename=$(basename $1)
  announce "Loading '$2' policy"
  kubectl cp "$1" "$3:/"
  kubectl exec $(basename $3) -- conjur policy load --replace "$2" "$filename"
}

has_serviceaccount() {
  kubectl get serviceaccount "$1" &> /dev/null;
}

has_namespace() {
  if kubectl get namespace  "$1" > /dev/null; then
    true
  else
    false
  fi
}

set_namespace() {
  if [[ $# != 1 ]]; then
    printf "Error in %s/%s - expecting 1 arg.\n" $(pwd) $0
    exit -1
  fi

  kubectl config set-context $(kubectl config current-context) --namespace="$1" > /dev/null
}

function wait_for_it() {
  local timeout=$1
  local spacer=2
  shift

  if ! [ $timeout = '-1' ]; then
    local times_to_run=$((timeout / spacer))

    echo "Waiting for '$@' up to $timeout s"
    for i in $(seq $times_to_run); do
      eval $@ > /dev/null && echo 'Success!' && break
      echo -n .
      sleep $spacer
    done

    eval $@
  else
    echo "Waiting for '$@' forever"

    while ! eval $@ > /dev/null; do
      echo -n .
      sleep $spacer
    done
    echo 'Success!'
  fi
}
