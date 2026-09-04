#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$DIR/.."

echo "🚀 Initializing and Applying Zero-Egress Architecture..."
cd "$ROOT_DIR/terraform"

terraform init
terraform validate
terraform apply -auto-approve

echo ""
echo "🎉 Deployment finished successfully! Check Terraform outputs for SSM and Lambda commands."
