#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"

AWS_PROFILE="${AWS_PROFILE:-kostya}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
AWS_REGION_US="${AWS_REGION_US:-us-east-1}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-Z081687731V8EF7SJR081}"
DOMAIN="${DOMAIN:-pinturaviva.varik.es}"
BUCKET="${BUCKET:-pinturaviva.varik.es}"
PRICE_CLASS="${PRICE_CLASS:-PriceClass_100}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd aws
require_cmd jq

"$ROOT_DIR/build-dist.sh"

if ! aws s3api head-bucket --bucket "$BUCKET" --profile "$AWS_PROFILE" >/dev/null 2>&1; then
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION" \
    --profile "$AWS_PROFILE"
fi

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --profile "$AWS_PROFILE"

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile "$AWS_PROFILE"

CERT_ARN="$(
  aws acm list-certificates \
    --region "$AWS_REGION_US" \
    --profile "$AWS_PROFILE" \
    --query "CertificateSummaryList[?DomainName=='$DOMAIN'].CertificateArn | [0]" \
    --output text
)"

if [ -z "$CERT_ARN" ] || [ "$CERT_ARN" = "None" ]; then
  CERT_ARN="$(
    aws acm request-certificate \
      --region "$AWS_REGION_US" \
      --domain-name "$DOMAIN" \
      --validation-method DNS \
      --profile "$AWS_PROFILE" \
      --query CertificateArn \
      --output text
  )"
fi

VALIDATION_JSON="$(
  aws acm describe-certificate \
    --region "$AWS_REGION_US" \
    --certificate-arn "$CERT_ARN" \
    --profile "$AWS_PROFILE" \
    --query "Certificate.DomainValidationOptions[0].ResourceRecord"
)"

VALIDATION_NAME="$(echo "$VALIDATION_JSON" | jq -r '.Name // empty')"
VALIDATION_VALUE="$(echo "$VALIDATION_JSON" | jq -r '.Value // empty')"

if [ -z "$VALIDATION_NAME" ] || [ -z "$VALIDATION_VALUE" ]; then
  for _ in $(seq 1 30); do
    sleep 5
    VALIDATION_JSON="$(
      aws acm describe-certificate \
        --region "$AWS_REGION_US" \
        --certificate-arn "$CERT_ARN" \
        --profile "$AWS_PROFILE" \
        --query "Certificate.DomainValidationOptions[0].ResourceRecord"
    )"
    VALIDATION_NAME="$(echo "$VALIDATION_JSON" | jq -r '.Name // empty')"
    VALIDATION_VALUE="$(echo "$VALIDATION_JSON" | jq -r '.Value // empty')"
    if [ -n "$VALIDATION_NAME" ] && [ -n "$VALIDATION_VALUE" ]; then
      break
    fi
  done
fi

if [ -z "$VALIDATION_NAME" ] || [ -z "$VALIDATION_VALUE" ]; then
  echo "ACM validation record was not ready for $DOMAIN" >&2
  exit 1
fi

cat > /tmp/pinturaviva-cert-validation.json <<JSON
{
  "Comment": "Validate $DOMAIN",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$VALIDATION_NAME",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          { "Value": "$VALIDATION_VALUE" }
        ]
      }
    }
  ]
}
JSON

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/pinturaviva-cert-validation.json \
  --profile "$AWS_PROFILE" >/dev/null

aws acm wait certificate-validated \
  --region "$AWS_REGION_US" \
  --certificate-arn "$CERT_ARN" \
  --profile "$AWS_PROFILE"

OAC_ID="$(
  aws cloudfront list-origin-access-controls \
    --profile "$AWS_PROFILE" \
    --query "OriginAccessControlList.Items[?Name=='$DOMAIN-oac'].Id | [0]" \
    --output text
)"

if [ -z "$OAC_ID" ] || [ "$OAC_ID" = "None" ]; then
  OAC_ID="$(
    aws cloudfront create-origin-access-control \
      --origin-access-control-config "Name=$DOMAIN-oac,Description=OAC for $DOMAIN,SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3" \
      --profile "$AWS_PROFILE" \
      --query "OriginAccessControl.Id" \
      --output text
  )"
fi

DISTRIBUTION_ID="$(
  aws cloudfront list-distributions \
    --profile "$AWS_PROFILE" \
    --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, '$DOMAIN')].Id | [0]" \
    --output text
)"

if [ -z "$DISTRIBUTION_ID" ] || [ "$DISTRIBUTION_ID" = "None" ]; then
  cat > /tmp/pinturaviva-cf-config.json <<JSON
{
  "CallerReference": "$DOMAIN-$(date +%s)",
  "Comment": "$DOMAIN static site",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "Aliases": {
    "Quantity": 1,
    "Items": ["$DOMAIN"]
  },
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3Origin",
        "DomainName": "$BUCKET.s3.$AWS_REGION.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        },
        "OriginAccessControlId": "$OAC_ID"
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["HEAD", "GET"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["HEAD", "GET"]
      }
    },
    "Compress": true,
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6"
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 10
      },
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 10
      }
    ]
  },
  "PriceClass": "$PRICE_CLASS",
  "ViewerCertificate": {
    "ACMCertificateArn": "$CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "Restrictions": {
    "GeoRestriction": {
      "RestrictionType": "none",
      "Quantity": 0
    }
  },
  "HttpVersion": "http2and3",
  "IsIPV6Enabled": true
}
JSON

  DISTRIBUTION_ID="$(
    aws cloudfront create-distribution \
      --distribution-config file:///tmp/pinturaviva-cf-config.json \
      --profile "$AWS_PROFILE" \
      --query "Distribution.Id" \
      --output text
  )"
fi

CLOUDFRONT_DOMAIN="$(
  aws cloudfront get-distribution \
    --id "$DISTRIBUTION_ID" \
    --profile "$AWS_PROFILE" \
    --query "Distribution.DomainName" \
    --output text
)"

cat > /tmp/pinturaviva-bucket-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipalReadOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::678685024251:distribution/$DISTRIBUTION_ID"
        }
      }
    }
  ]
}
JSON

aws s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy file:///tmp/pinturaviva-bucket-policy.json \
  --profile "$AWS_PROFILE"

cat > /tmp/pinturaviva-alias.json <<JSON
{
  "Comment": "Alias $DOMAIN to CloudFront",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$CLOUDFRONT_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "AAAA",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$CLOUDFRONT_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
JSON

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/pinturaviva-alias.json \
  --profile "$AWS_PROFILE" >/dev/null

aws s3 cp "$DIST_DIR/index.html" "s3://$BUCKET/index.html" \
  --cache-control "no-store" \
  --content-type "text/html; charset=utf-8" \
  --profile "$AWS_PROFILE"

aws s3 cp "$DIST_DIR/styles.css" "s3://$BUCKET/styles.css" \
  --cache-control "public, max-age=31536000, immutable" \
  --content-type "text/css; charset=utf-8" \
  --profile "$AWS_PROFILE"

aws s3 cp "$DIST_DIR/script.js" "s3://$BUCKET/script.js" \
  --cache-control "public, max-age=31536000, immutable" \
  --content-type "application/javascript; charset=utf-8" \
  --profile "$AWS_PROFILE"

aws s3 cp "$DIST_DIR/robots.txt" "s3://$BUCKET/robots.txt" \
  --cache-control "public, max-age=3600" \
  --content-type "text/plain; charset=utf-8" \
  --profile "$AWS_PROFILE"

aws s3 cp "$DIST_DIR/sitemap.xml" "s3://$BUCKET/sitemap.xml" \
  --cache-control "public, max-age=3600" \
  --content-type "application/xml; charset=utf-8" \
  --profile "$AWS_PROFILE"

aws s3 sync "$DIST_DIR/assets/" "s3://$BUCKET/assets/" \
  --cache-control "public, max-age=31536000, immutable" \
  --profile "$AWS_PROFILE"

aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --profile "$AWS_PROFILE" >/dev/null

echo "Domain: $DOMAIN"
echo "Bucket: $BUCKET"
echo "Certificate: $CERT_ARN"
echo "Distribution: $DISTRIBUTION_ID"
echo "CloudFront: $CLOUDFRONT_DOMAIN"
