#!/bin/bash

set -e

echo ">>>>>>>>>> Testing secure manifests (should PASS):"
for f in ./secure-manifests/*.yaml; do
  echo "$f:"
  kubectl apply -f "$f" && echo ">>>>>>>>>> Passed (as expected)" || echo ">>>>>>>>>> Failed (but should be passed)"
done

kubectl get pods -n audit-zone