#!/usr/bin/env bash

AUDIT_LOG="audit.log"
OUTPUT="audit-extract.json"

echo "Fast extracting suspicious events using jq..."
echo "Source: $AUDIT_LOG"
echo "Output: $OUTPUT"
echo "----------------------------------------------------------"

jq -c '
    select(

        # 1. Secrets access by monitoring SA
        (.verb=="get" and .objectRef.resource == "secrets")
        or

        # 2. Privileged pod creation
        (
            .verb == "create"
            and .objectRef.resource == "pods"
            and any(.requestObject.spec.containers[]?.securityContext.privileged; . == true)
        )
        or

        # 3. kubectl exec into foreign namespace
        (.verb == "create" and .objectRef.subresource=="exec")
        or

        # 4. Deletion of audit-policy.yaml
        (
            .verb == "delete"
            and (
                .objectRef.name == "audit-policy.yaml"
                or (.requestURI | contains("audit-policy.yaml"))
            )
        )
        or

        # 5. RoleBinding creation
        (.verb == "create" and .objectRef.resource == "rolebindings")
    )
' "$AUDIT_LOG" > "$OUTPUT"

echo "----------------------------------------------------------"
echo "Done. Extracted:"
wc -l "$OUTPUT"
