#!/bin/bash

# Render Helm templates to a single YAML file
helm template java-app ./helm > rendered-manifest.yaml

# Send to Kubesec API for scanning
scan_result=$(curl -sSX POST --data-binary @rendered-manifest.yaml https://v2.kubesec.io/scan)
scan_score=$(echo "$scan_result" | jq '.[0].score')
scan_message=$(echo "$scan_result" | jq -r '.[0].scoring[]?.reason // empty')

# Evaluate score
if [[ "$scan_score" -ge 5 ]]; then
  echo "Score is $scan_score"
  echo "Kubesec Scan: $scan_message"
else
  echo "Score is $scan_score, which is less than or equal to 5."
  echo "Scanning Kubernetes Resource has Failed"
  exit 1
fi
