#!/bin/bash

NAMESPACE=$1
POD_NAME=$2
CREDS=$3


kubectl exec -i "$POD_NAME" -n "$NAMESPACE" -- bash -c "mysqlsh ${CREDS}@localhost --py -e 'tools.clusterset_create()'"