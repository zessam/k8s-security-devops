#!/bin/bash
set -e

API_KEY=${1:-""}
CVSS_THRESHOLD=${2:-7}

DC_VERSION="9.0.7"
DC_DIR="./tools/dependency-check"
DC_BIN="$DC_DIR/bin/dependency-check.sh"
DC_DATA="$HOME/.dependency-check-data"

# Create directories
mkdir -p "$DC_DATA"
mkdir -p "./tools"
mkdir -p "./reports"

# Download Dependency-Check CLI if not present
if [ ! -f "$DC_BIN" ]; then
  echo "⬇️ Downloading OWASP Dependency-Check CLI v$DC_VERSION..."
  curl -Ls "https://github.com/jeremylong/DependencyCheck/releases/download/v${DC_VERSION}/dependency-check-${DC_VERSION}-release.zip" -o ./tools/dc.zip
  unzip -q ./tools/dc.zip -d ./tools/
  chmod +x "$DC_BIN"
fi

# Add API key if provided
if [ -n "$API_KEY" ]; then
    API_ARGS="--nvdApiKey $API_KEY"
else
    API_ARGS=""
fi

# Run the scan
echo "🔍 Running OWASP Dependency-Check scan..."
"$DC_BIN" \
  --scan "$(pwd)" \
  --format SARIF \
  --project "security-scan" \
  --failOnCVSS "$CVSS_THRESHOLD" \
  --enableRetired \
  --out "$(pwd)/reports" \
  --data "$DC_DATA" \
  $API_ARGS

echo "✅ Scan complete. SARIF report saved to: reports/dependency-check-report.sarif"
