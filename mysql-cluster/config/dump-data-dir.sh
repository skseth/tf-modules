#!/bin/bash

# Configuration

NAMESPACE=${1:-"infra"}
PVC_NAME=${2:-"data-mysql-1"}
TARGET_DIR=${3:-"/"}  # Default to root of PVC if not specified
POD_NAME_PREFIX="pvc-exporter"
POD_NAME="${POD_NAME_PREFIX}-$(date +%s)"
LOCAL_FILE="mysql.tar.gz"

if [ -z "$PVC_NAME" ]; then
    echo "Usage: $0 <pvc-name> [directory-in-pvc]"
    exit 1
fi

echo "Creating helper pod to mount PVC: $PVC_NAME..."

kubectl get pods -n "$NAMESPACE" -o name | grep "^pod/$POD_NAME_PREFIX" | xargs -r kubectl delete

# 1. Run a temporary pod mounted with the PVC
kubectl run "$POD_NAME" -n "$NAMESPACE" --image=busybox --restart=Never --overrides='
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
            "mountPath": "/mnt/pvc"
          }
        ]
      }
    ],
    "volumes": [
      {
        "name": "pvc-storage",
        "persistentVolumeClaim": {
          "claimName": "'"$PVC_NAME"'"
        }
      }
    ]
  }
}' || exit 1


# 2. Wait for the pod to be ready
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=Ready "pod/$POD_NAME" --timeout=60s  -n "$NAMESPACE" || exit 1

# 3. Tar the contents and stream to host, OR tar inside and copy
echo "Compressing and downloading data from /mnt/pvc$TARGET_DIR..."
# Method: tar to stdout and pipe to a local file
rm "$LOCAL_FILE" 
kubectl exec "$POD_NAME"  -n "$NAMESPACE" --  tar -czvf mysql.tar.gz /mnt/pvc || exit 1

kubectl cp "$NAMESPACE/$POD_NAME:/mysql.tar.gz" "$LOCAL_FILE"  || exit 1

# 4. Clean up the pod
echo "Cleaning up..."
kubectl delete pod "$POD_NAME"  -n "$NAMESPACE" --now

echo "Done! PVC contents saved to: $LOCAL_FILE"
