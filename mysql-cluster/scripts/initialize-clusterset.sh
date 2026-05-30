#!/bin/bash

NAMESPACE=$1
POD_NAME=$2
ROOT_PASSWORD=$3
URI=$3


kubectl exec -i "$POD_NAME" -n "$NAMESPACE" -- bash <<EOF
until mysqladmin ping -h "localhost" -u "root" -p"$ROOT_PASSWORD" --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
done
mysqlsh ${URI} --py -e 'tools.clusterset_create()'
EOF
