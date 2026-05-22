#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/common.sh"

namespace="${1:-infra}"

pvc_name="${pvc_names[0]}"

pod_name="${pod_prefix}-$(date +%s)"
delete_pod_prefix "$namespace" "$pod_prefix"
pod_name="${pod_prefix}-$(date +%s)"
echo "creating pod $pod_name"
create_pod "$namespace" "$pod_name" "$pvc_name"

