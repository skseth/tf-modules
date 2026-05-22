#!/bin/bash

source ./common.sh

create_pvcs() {
  echo "Setting up PVCs"
  # check pvcs exist
  for pvc_name in "${pvc_names[@]}"; do
    if pvc_exists "$namespace" "$pvc_name"; then
      echo "pvc $pvc_name exists in namespace $namespace"
    else
      echo "Creating pvc $pvc_name in namespace $namespace"
      create_data_pvc "$namespace" "$pvc_name"
    fi
  done
}


create_pvcs




