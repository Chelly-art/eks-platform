#!/usr/bin/env bash
# Run inside a terraform dir after apply. Usage: verify-state.sh <state-key>
set -euo pipefail
KEY="${1:?state key}"; B="${STATE_BUCKET:?}"
echo "1/4 state object exists in S3"
aws s3api head-object --bucket "$B" --key "$KEY" >/dev/null
echo "2/4 state holds resources"
N=$(terraform state list | wc -l); [ "$N" -gt 0 ] || { echo "empty state"; exit 1; }
echo "   $N resources tracked"
echo "3/4 lock released"
if aws s3api head-object --bucket "$B" --key "${KEY}.tflock" >/dev/null 2>&1; then
  echo "lock file still present"; exit 1
fi
echo "4/4 no drift (plan must be empty)"
set +e
terraform plan -detailed-exitcode -input=false -lock-timeout=5m >/dev/null
RC=$?
set -e
[ "$RC" -eq 0 ] || { echo "plan exit code $RC (2 = pending changes/drift)"; exit 1; }
echo "State OK and ready"
