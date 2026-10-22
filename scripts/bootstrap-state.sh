#!/usr/bin/env bash
# Idempotently creates the S3 bucket used for state AND state locking (use_lockfile).
set -euo pipefail
B="${STATE_BUCKET:?}"; R="${AWS_REGION:?}"
if aws s3api head-bucket --bucket "$B" 2>/dev/null; then
  echo "Bucket $B exists"
else
  if [ "$R" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$B" --region "$R"
  else
    aws s3api create-bucket --bucket "$B" --region "$R" --create-bucket-configuration "LocationConstraint=$R"
  fi
fi
aws s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$B" --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket "$B" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
echo "State bucket ready: $B"
