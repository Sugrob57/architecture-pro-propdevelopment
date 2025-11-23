## create_user.sh

#!/bin/bash

set -e

USER=$1
GROUP=$2
OUT_DIR="users"

if [ -z "$USER" ] || [ -z "$GROUP" ]; then
  echo "Usage: ./create-minikube-user.sh <username> <group>"
  exit 1
fi

mkdir -p $OUT_DIR

echo "🔐 Exporting Minikube CA..."

# Export CA from minikube VM
minikube ssh "sudo cat /var/lib/minikube/certs/ca.crt" > $OUT_DIR/ca.crt
minikube ssh "sudo cat /var/lib/minikube/certs/ca.key" > $OUT_DIR/ca.key

echo "📌 Using CA:"
echo "  - $OUT_DIR/ca.crt"
echo "  - $OUT_DIR/ca.key"

# Generate user private key
openssl genrsa -out $OUT_DIR/${USER}.key 2048

# Create CSR with group O=<group>
openssl req -new -key $OUT_DIR/${USER}.key \
  -out $OUT_DIR/${USER}.csr \
  -subj "/CN=${USER}/O=${GROUP}"

# Sign CSR with Minikube CA
openssl x509 -req \
  -in $OUT_DIR/${USER}.csr \
  -CA $OUT_DIR/ca.crt \
  -CAkey $OUT_DIR/ca.key \
  -CAcreateserial \
  -out $OUT_DIR/${USER}.crt \
  -days 365

echo "📜 Certificate generated for user ${USER}"

# Get Minikube API server address
APISERVER=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="minikube")].cluster.server}')

# Create kubeconfig file
KUBECONFIG_FILE="$OUT_DIR/${USER}-kubeconfig"

kubectl config --kubeconfig=$KUBECONFIG_FILE set-cluster minikube \
  --server="$APISERVER" \
  --certificate-authority=$OUT_DIR/ca.crt \
  --embed-certs=true

kubectl config --kubeconfig=$KUBECONFIG_FILE set-credentials ${USER} \
  --client-certificate=$OUT_DIR/${USER}.crt \
  --client-key=$OUT_DIR/${USER}.key \
  --embed-certs=true

kubectl config --kubeconfig=$OUT_DIR/${USER}-kubeconfig set-context ${USER}@minikube \
  --cluster=minikube \
  --user=${USER}

kubectl config --kubeconfig=$OUT_DIR/${USER}-kubeconfig use-context ${USER}@minikube

echo ""
echo "🎉 User ${USER} created successfully!"
echo "📁 Files stored in: ${OUT_DIR}"
echo "  - ${USER}.key"
echo "  - ${USER}.crt"
echo "  - ${USER}.csr"
echo "  - ${USER}-kubeconfig"
echo ""
echo "👉 Use this kubeconfig:"
echo "   export KUBECONFIG=$(pwd)/${OUT_DIR}/${USER}-kubeconfig"


