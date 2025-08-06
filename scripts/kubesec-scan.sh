#!/bin/bash

# Create a temp output directory
mkdir -p rendered

# Render Helm templates individually
helm template java-app ./helm -f ./helm/values.yaml --show-only templates/deployment.yaml > rendered/deployment.yaml
helm template java-app ./helm -f ./helm/values.yaml --show-only templates/service.yaml > rendered/service.yaml
helm template java-app ./helm -f ./helm/values.yaml --show-only templates/configmap.yaml > rendered/configmap.yaml

# Initialize fail flag
fail=0

# Loop over each rendered YAML file and scan it
for file in rendered/*.yaml; do
  echo "Scanning $file ..."
  scan_result=$(curl -sSX POST --data-binary @"$file" https://v2.kubesec.io/scan)
  scan_score=$(echo "$scan_result" | jq '.[0].score')
  scan_message=$(echo "$scan_result" | jq -r '.[0].scoring[]?.reason // empty')

  if [[ "$scan_score" -ge 5 ]]; then
    echo "✅ $file passed with score: $scan_score"
    echo "$scan_message"
  else
    echo "❌ $file failed with score: $scan_score"
    echo "$scan_message"
    fail=1
  fi
done

# Exit with error if any failed
if [[ $fail -ne 0 ]]; then
  echo "❌ One or more Kubernetes manifests failed the Kubesec scan."
  exit 1
else
  echo "✅ All manifests passed the Kubesec scan."
fi
