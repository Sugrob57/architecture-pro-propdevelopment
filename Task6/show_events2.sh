#!/usr/bin/env bash

AUDIT_LOG="audit.log"
OUTPUT="audit-extract.json"

echo "Creating suspicious events extract..."
echo "Source: $AUDIT_LOG"
echo "Output: $OUTPUT"
echo "----------------------------------------------------------"

> "$OUTPUT"

START_TIME=$(date +%s)
COUNT=0

while IFS= read -r LINE; do
    COUNT=$((COUNT + 1))

    # Каждые 500 строк – выводим прогресс
    if (( COUNT % 500 == 0 )); then
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        SPEED=$((COUNT / (ELAPSED + 1)))
        echo "[INFO] Processed $COUNT lines (elapsed ${ELAPSED}s, ~${SPEED} lines/sec)"
    fi

    #### 1. Доступ к Secrets сервис-аккаунтом monitoring ####
    if echo "$LINE" | jq -e '
        .verb=="get"
    ' >/dev/null 2>&1 &&
       echo "$LINE" | jq -e '.objectRef.resource == "secrets"' >/dev/null 2>&1; then
        echo "$LINE" >> "$OUTPUT"
        continue
    fi

    #### 2. Привилегированный под ####
    if echo "$LINE" | jq -e '
        .objectRef.resource == "pods"
        and (.requestObject.spec.containers[]?.securityContext.privileged == true)
    ' >/dev/null 2>&1; then
        echo "$LINE" >> "$OUTPUT"
        continue
    fi

    #### 3. kubectl exec в чужом NS ####
    if echo "$LINE" | jq -e '
        select(.verb=="create" and .objectRef.subresource=="exec")
    ' >/dev/null 2>&1; then
        echo "$LINE" >> "$OUTPUT"
        continue
    fi

    #### 4. Удаление audit-policy.yaml ####
    if echo "$LINE" | jq -e '
        .verb == "delete"
        and (
            .objectRef.name == "audit-policy.yaml"
            or (.requestURI | contains("audit-policy.yaml"))
        )
    ' >/dev/null 2>&1; then
        echo "$LINE" >> "$OUTPUT"
        continue
    fi

    #### 5. Создание RoleBinding ####
    if echo "$LINE" | jq -e '
        .verb == "create"
        and .objectRef.resource == "rolebindings"
    ' >/dev/null 2>&1; then
        echo "$LINE" >> "$OUTPUT"
        continue
    fi

done < "$AUDIT_LOG"

END_TIME=$(date +%s)
ELAPSED_TOTAL=$((END_TIME - START_TIME))

echo "----------------------------------------------------------"
echo "Done. Total processed: $COUNT lines"
echo "Total time: ${ELAPSED_TOTAL}s"
echo "Extract saved to: $OUTPUT"
