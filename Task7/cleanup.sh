#!/bin/bash

set -e

echo "delete namespace audit-zone"
kubectl delete ns audit-zone --ignore-not-found=true

echo "delete ConstraintTemplates и Constraints"
kubectl delete -f gatekeeper/constraints/ --ignore-not-found=true || true
kubectl delete -f gatekeeper/constraint-templates/ --ignore-not-found=true || true

echo "delete Gatekeeper"
kubectl delete -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.16/deploy/gatekeeper.yaml --ignore-not-found=true || true

echo "delete CRDs for Gatekeeper"
kubectl delete crd constrainttemplates.templates.gatekeeper.sh --ignore-not-found=true || true
kubectl delete crd k8shostpaths.constraints.gatekeeper.sh --ignore-not-found=true || true
kubectl delete crd k8sprivilegeds.constraints.gatekeeper.sh --ignore-not-found=true || true
kubectl delete crd k8srunasnonroots.constraints.gatekeeper.sh --ignore-not-found=true || true
kubectl delete crd k8sreadonlyrootfilesystems.constraints.gatekeeper.sh --ignore-not-found=true || true

echo "Cleanup completed"