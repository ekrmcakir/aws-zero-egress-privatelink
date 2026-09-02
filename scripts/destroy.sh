#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$DIR/.."

echo "⚠️  Destroying Zero-Egress Architecture..."
cd "$ROOT_DIR/terraform"

terraform destroy -auto-approve

echo "✅ All resources destroyed cleanly."
