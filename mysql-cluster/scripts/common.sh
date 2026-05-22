#!/bin/bash

delete_pvc() {
  local namespace pvc_name

  namespace=$1
  pvc_name=$2

  kubectl delete pvc "$pvc_name" -n "$namespace" --ignore-not-found || exit 1
}

pvc_exists() {
  local namespace pvc_name

  namespace=$1
  pvc_name=$2

  kubectl get pvc "$pvc_name" -n "$namespace" > /dev/null 2>&1
  return $?
}


create_data_pvc() {
  local namespace
  namespace=$1
  pvc_name=$2

  cat <<EOF | kubectl apply -n "$namespace" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "$pvc_name"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
}

delete_pod() {
    local namespace pod_name

    namespace=$1
    pod_name=$2
    kubectl delete pod "$pod_name"  -n "$namespace" --now --ignore-not-found 
}

delete_pod_prefix() {
    local namespace pod_name

    namespace=$1
    prefix=$2

    kubectl get pods -n "$namespace" -o name | grep "^pod/$prefix" | xargs -r kubectl delete -n "$namespace"
}

create_pod() {
  local namespace pod_name target_pvc

  namespace=$1
  pod_name=$2
  target_pvc=$3

  echo "Initializing pod $namespace/$pod_name with target pvc $target_pvc"

  kubectl run "$pod_name" -n "$namespace" --image=busybox --restart=Never --overrides='
  {
    "spec": {
      "containers": [
        {
          "name": "pvc-helper",
          "image": "busybox",
          "command": ["/bin/sh", "-c", "sleep 3600"],
          "volumeMounts": [
            {
              "name": "target",
              "mountPath": "/mnt/target"
            }                                     
          ]
        }
      ],
      "volumes": [
        {
          "name": "target",
          "persistentVolumeClaim": {
            "claimName": "'"$target_pvc"'"
          }
        }
      ]
    }
  }' || exit 1

  echo "Waiting for pod $pod_name to be ready..."
  kubectl wait --for=condition=Ready "pod/$pod_name" --timeout=60s  -n "$namespace" || exit 1

}

copy_seed_data() {
  local namespace pod_name seed_file

  namespace=$1
  pod_name=$2
  seed_file=$3

  seed_file_remote=/mysql.tar.gz

  echo "Deleting existing seed file $seed_file_remote in pod $namespace/$pod_name, it it exists"
  kubectl exec -i "$pod_name" -n "$namespace" -- sh -c "rm -rf $seed_file_remote"

  echo "Copying seed file $seed_file to $namespace/$pod_name:$seed_file_remote"
  kubectl cp "$seed_file" "$namespace/$pod_name:$seed_file_remote"  || exit 1
}

initialize_data_pvc() {
  local namespace pvc_name
  namespace=$1
  pod_name=$2

  echo "Cleaning up and untarring seed data into pvc attached to $pod_name"
  kubectl exec -i "$pod_name" -n "$namespace" -- sh -c "rm -rf /mnt/target/* && tar -zxf /mysql.tar.gz  --strip-components=2 -C /mnt/target && rm /mnt/target/auto.cnf && ls /mnt/target"

}

export namespace=${1:?Namespace is required as the first argument}
pvc_names_arg=${2:?List of pvcs comma separated}

IFS=',' read -r -a pvc_names <<< "$pvc_names_arg"

export pod_prefix="mysql-init"
