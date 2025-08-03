#!/bin/bash
set -e

API_KEY=${1:-""}
CVSS_THRESHOLD=${2:-7}

# Create cache directory
mkdir -p ~/.dependency-check-data

# Add API key args if provided
if [ -n "$API_KEY" ]; then
    API_ARGS="--nvdApiKey $API_KEY"
else
    API_ARGS=""
fi

# Run scan with cached database
docker run --rm \
    -v $(pwd):/src \
    -v ~/.dependency-check-data:/usr/share/dependency-check/data \
    owasp/dependency-check:latest \
    --scan /src \
    --format SARIF \
    --project security-scan \
    --failOnCVSS $CVSS_THRESHOLD \
    --enableRetired \
    --out /src/reports \
    $API_ARGS

echo "Scan complete. SARIF report: reports/dependency-check-report.sarif"