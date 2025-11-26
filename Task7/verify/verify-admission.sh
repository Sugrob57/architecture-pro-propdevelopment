#!/bin/bash

set -e

echo ">>>>>>>>>> Testing insecure manifests (should FAIL):"
for f in ./insecure-manifests/*.yaml; do
  echo "$f:"
  kubectl apply -f "$f" && echo ">>>>>>>>>> Passed (but should be failed)" || echo ">>>>>>>>>> Failed (as expected)"
done