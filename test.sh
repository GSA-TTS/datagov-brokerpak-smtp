#!/bin/bash

# Test that a provisioned instance is set up properly and meets requirements
#   ./test.sh BINDINGINFO.json
#
# Returns 0 (if all tests PASS)
#      or 1 (if any test FAILs).

set -e
retval=0

if [[ -z ${1+x} ]] ; then
    echo "Usage: ./test.sh BINDINGINFO.json"
    exit 1
fi

SERVICE_INFO="$(jq -r .credentials < "$1")"

domain=`echo $SERVICE_INFO | jq -r '.domain_arn | split("/")[1]'`

echo "Running tests on ${domain}..."

if [ "$domain" = "test.com" ]; then
  export output=`echo $SERVICE_INFO | jq '. | select(.required_records != null)'`
  if [ -z "$output" ]; then
    echo "Failed"
  else
    echo "Records outputted successfully"
  fi
else

  echo "Is dmarc valid?"
  checkdmarc $domain | jq '.dmarc'
  checkdmarc $domain | jq --exit-status '.dmarc.valid'

  echo "Is spf valid?"
  checkdmarc $domain | jq '.spf'
  checkdmarc $domain | jq --exit-status '.spf.valid'

fi
