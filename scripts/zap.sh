#!/bin/bash

# Set the EKS LoadBalancer URL and port
applicationURL="http://a01c5c313c42f497d82b3d6f95640868-541966697.eu-west-1.elb.amazonaws.com"
PORT=80  # Change if your service uses a different port

echo "Running ZAP scan on: $applicationURL:$PORT"

# Make working directory writable for the report
chmod 777 "$(pwd)"
echo "User: $(id -u):$(id -g)"

# Run OWASP ZAP with custom rules
sudo docker run -v "$(pwd)":/zap/wrk/:rw -t zaproxy/zap-stable zap-api-scan.py \
  -t "$applicationURL:$PORT/v3/api-docs" \
  -f openapi \
  -c zap_rules \
  -r zap_report.html

exit_code=$?

# Move HTML Report
mkdir -p owasp-zap-report
mv zap_report.html owasp-zap-report/

echo "Exit Code : $exit_code"

if [[ ${exit_code} -ne 0 ]]; then
    echo "⚠️  OWASP ZAP Report has Low/Medium/High Risk. Please check the HTML Report"
    exit 1
else
    echo "✅ OWASP ZAP did not report any Risk"
fi

# Optional: Generate config file for future tuning
# docker run -v "$(pwd)":/zap/wrk/:rw -t owasp/zap2docker-weekly zap-api-scan.py \
#   -t "$applicationURL:$PORT/v3/api-docs" -f openapi -g gen_file
