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

create_seed_pvc() {
  local namespace src_pvc_name

  namespace=$1
  src_pvc_name=$2

  cat <<EOF | kubectl apply -n "$namespace" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "$src_pvc_name"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
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
    kubectl delete pod "$pod_name"  -n "$namespace" --now
}

delete_pod_prefix() {
    local namespace pod_name

    namespace=$1
    prefix=$2

    kubectl get pods -n "$namespace" -o name | grep "^pod/$prefix" | xargs -r kubectl delete -n "$namespace"
}

create_pod() {
  local namespace pod_name src_pvc target_pvc

  namespace=$1
  pod_name=$2
  src_pvc=$3
  targeta_pvc=$4
  targetb_pvc=$5

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
              "name": "pvc-storage",
              "mountPath": "/mnt/src"
            },
            {
              "name": "targeta",
              "mountPath": "/mnt/targeta"
            },
            {
              "name": "targetb",
              "mountPath": "/mnt/targetb"
            }                                     
          ]
        }
      ],
      "volumes": [
        {
          "name": "pvc-storage",
          "persistentVolumeClaim": {
            "claimName": "'"$src_pvc"'"
          }
        },         
        {
          "name": "targeta",
          "persistentVolumeClaim": {
            "claimName": "'"$targeta_pvc"'"
          }
        },
        {
          "name": "targetb",
          "persistentVolumeClaim": {
            "claimName": "'"$targetb_pvc"'"
          }
        }            
      ]
    }
  }' || exit 1

    echo "Waiting for pod to be ready..."
  kubectl wait --for=condition=Ready "pod/$pod_name" --timeout=60s  -n "$namespace" || exit 1

}

copy_seed_data() {
  local namespace pod_name seed_file

  namespace=$1
  pod_name=$2
  seed_file=$3

  seed_file_remote=/mnt/src/mysql.tar.gz

  echo "Deleting existing seed file, it it exists"
  kubectl exec -i "$pod_name" -n "$namespace" -- sh -c "rm -rf $seed_file_remote"

  echo "Copying seed file $seed_file to $seed_file_remote"
  kubectl cp "$seed_file" "$namespace/$pod_name:$seed_file_remote"  || exit 1
}

initialize_data_pvcs() {
  local namespace pvc_name
  namespace=$1
  pod_name=$2

  kubectl exec -i "$pod_name" -n "$namespace" -- sh -c "rm -rf /mnt/targeta/* && tar -zxf /mnt/src/mysql.tar.gz  --strip-components=2 -C /mnt/targeta && rm /mnt/targeta/auto.cnf"
  kubectl exec -i "$pod_name" -n "$namespace" -- sh -c "rm -rf /mnt/targetb/* && tar -zxf /mnt/src/mysql.tar.gz  --strip-components=2 -C /mnt/targetb && rm /mnt/targetb/auto.cnf"
}


export seed_pvc="mysql-seed-pvc"
export namespaces=("infra" "infra-repl")
export data_pvcs=("data-mysql-0" "data-mysql-1")
export pod_prefix="pvc-browser"