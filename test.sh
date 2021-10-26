#!/bin/bash

set -e

export SERVICE_INFO=$(echo "eden --client user --client-secret pass --url http://127.0.0.1:8080 credentials -b binding -i ${INSTANCE_NAME:-instance-${USER}}")

echo "Running tests..."

# Validate SPF Record (this only works if the entire domain is setup in AWS)
# - Get email domain from eden output
# - Verify that the spf record exists in the lookup

domain=`$SERVICE_INFO | jq -r '.domain_arn | split("/")[1]'`
nslookup -type=txt $domain | grep "v=spf1 include:amazonses.com -all"
