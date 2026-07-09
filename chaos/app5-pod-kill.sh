#!/usr/bin/env bash
# Kills a running app5-fileservice pod and times Kubernetes' real self-heal
# recovery by polling `kubectl get deployment` until availableReplicas is
# back to the desired count. All timing below is measured live with `date`
# - nothing here is a hardcoded or example number.
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
DEPLOYMENT="${DEPLOYMENT:-app5-app5-fileservice}"
LABEL_SELECTOR="app.kubernetes.io/name=app5-fileservice,app.kubernetes.io/instance=app5"
POLL_INTERVAL_SECONDS=1
POLL_TIMEOUT_SECONDS=120

echo "Pods before kill:"
kubectl -n "$NAMESPACE" get pods -l "$LABEL_SELECTOR"

POD=$(kubectl -n "$NAMESPACE" get pods -l "$LABEL_SELECTOR" -o jsonpath='{.items[0].metadata.name}')
if [ -z "$POD" ]; then
  echo "No pod found for selector '$LABEL_SELECTOR' in namespace '$NAMESPACE'." >&2
  exit 1
fi

DESIRED=$(kubectl -n "$NAMESPACE" get deployment "$DEPLOYMENT" -o jsonpath='{.spec.replicas}')

echo
echo "Killing pod: $POD (desired replica count: $DESIRED)"
start_epoch=$(date +%s)
kubectl -n "$NAMESPACE" delete pod "$POD" --wait=false

echo "Polling deployment/$DEPLOYMENT every ${POLL_INTERVAL_SECONDS}s until availableReplicas >= $DESIRED ..."
elapsed=0
while [ "$elapsed" -lt "$POLL_TIMEOUT_SECONDS" ]; do
  available=$(kubectl -n "$NAMESPACE" get deployment "$DEPLOYMENT" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)
  available=${available:-0}
  now_epoch=$(date +%s)
  elapsed=$((now_epoch - start_epoch))
  echo "  [+${elapsed}s] availableReplicas=$available/$DESIRED"

  if [ "$available" -ge "$DESIRED" ]; then
    end_epoch=$(date +%s)
    recovery_seconds=$((end_epoch - start_epoch))
    echo
    echo "Recovered: $DESIRED/$DESIRED replicas available."
    echo "Real self-heal recovery time: ${recovery_seconds}s (pod delete -> deployment back to desired replica count)"
    exit 0
  fi

  sleep "$POLL_INTERVAL_SECONDS"
done

echo "Timed out after ${POLL_TIMEOUT_SECONDS}s waiting for recovery." >&2
exit 1
