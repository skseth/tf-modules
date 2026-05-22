#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/common.sh"

export seed_src=${3:?Seed source file a .tar.gz file}

delete_pvcs() {
  echo "Setting up PVCs"
  # check pvcs exist
  for pvc_name in "${pvc_names[@]}"; do
    if pvc_exists "$namespace" "$pvc_name"; then
      echo "pvc $pvc_name exists in namespace $namespace ... deleting"
      delete_pvc "$namespace" "$pvc_name"
    else
      echo "pvc $pvc_name does not exist in namespace $namespace"
    fi
  done
}

delete_pvcs
