#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/common.sh"

setup_pvcs() {
  echo "Setting up PVCs"
  # check pvcs exist
  for pvc_name in "${pvc_names[@]}"; do
    if pvc_exists "$namespace" "$pvc_name"; then
      echo "pvc $pvc_name exists in namespace $namespace"
    else
      echo "pvc $pvc_name does not exist in namespace $namespace"
      exit 1
    fi
  done

  # check pvcs exist
  for pvc_name in "${pvc_names[@]}"; do
    pod_name="mysql-init-$(date +%s)"

    echo "Creating pod $pod_name"
    create_pod "$namespace" "$pod_name" "$pvc_name"
    echo "Copy seed sec $seed_src"
    copy_seed_data "$namespace" "$pod_name" "$seed_src"
    echo "Initializing the data pvc $pvc_name"
    initialize_data_pvc "$namespace" "$pod_name"
    delete_pod "$namespace" "$pod_name"
  done
}

cleanup() {
  echo "Cleaning up..."
  delete_pod_prefix "$namespace" "$pod_prefix"
}

trap "cleanup" EXIT

setup_pvcs




