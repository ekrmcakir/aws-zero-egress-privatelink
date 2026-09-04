#!/bin/bash
set -xe

echo "=== Initializing Zero-Egress Air-Gapped EC2 Workload ==="

# Wait for SSM Agent to start (pre-installed in Amazon Linux 2023)
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

# Create internal microservice heartbeat script
cat << 'EOF' > /opt/internal-workload.sh
#!/bin/bash
BUCKET_NAME="${s3_bucket_name}"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "ec2-airgapped")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "[$$TIMESTAMP] Executing private zero-egress heartbeat for $$INSTANCE_ID"

# 1. Test S3 Gateway Endpoint write (internal AWS backbone)
echo "{\"instance_id\": \"$$INSTANCE_ID\", \"timestamp\": \"$$TIMESTAMP\", \"status\": \"HEALTHY_AIRGAPPED\", \"egress_mode\": \"ZERO_EGRESS\"}" > /tmp/heartbeat.json

aws s3 cp /tmp/heartbeat.json "s3://$$BUCKET_NAME/telemetry/$$INSTANCE_ID-status.json" --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region || echo "us-east-1") || echo "S3 write failed (check endpoint/IAM)"

echo "[$$TIMESTAMP] Heartbeat cycle completed successfully."
EOF

chmod +x /opt/internal-workload.sh

# Run first heartbeat
/opt/internal-workload.sh

echo "=== Setup Completed Successfully ==="
