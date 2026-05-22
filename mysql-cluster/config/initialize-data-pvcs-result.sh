#!/bin/bash

source ./common.sh

for namespace in "${namespaces[@]}"; do
  echo "=========== namespace: $namespace"
  if pvc_exists "$namespace" "$seed_pvc"; then
    echo "seed pvc exists"
  else
    echo "creating seed pvc"
    create_seed_pvc "$namespace" "$seed_pvc"
  fi

  for data_pvc in "${data_pvcs[@]}"; do
    if pvc_exists "$namespace" "$data_pvc"; then
      echo "data pvc $data_pvc exists in namespace $namespace"
    else
      echo "creating data pvc $data_pvc in namespace $namespace"
      create_data_pvc "$namespace" "$data_pvc"
    fi
  done

  delete_pod_prefix "$namespace" "$pod_prefix"

  pod_name="${pod_prefix}-$(date +%s)"
  echo "creating pod $pod_name"
  create_pod "$namespace" "$pod_name" "$seed_pvc" "${data_pvcs[0]}" "${data_pvcs[1]}"
  echo "creating seed data"
  copy_seed_data "$namespace" "$pod_name" "mysql.tar.gz"
  echo "initializing data pvcs"
  initialize_data_pvcs "$namespace" "$pod_name"
  echo "deleting pod $pod_name"
  delete_pod "$namespace" "$pod_name"
done


