"""
Network Sentinel - Zero-Egress VPC Connectivity & Leak Verification Agent
Runs inside VPC to verify air-gapped isolation and PrivateLink connectivity.
"""

import os
import json
import socket
import time

socket.setdefaulttimeout(3.0)

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
    s3_client = boto3.client(
        "s3",
        region_name=os.environ.get("AWS_REGION", "us-east-1"),
        config=Config(connect_timeout=3, read_timeout=3, retries={"max_attempts": 1})
    )
except ImportError:
    boto3 = None
    ClientError = Exception
    s3_client = None

S3_BUCKET_NAME = os.environ.get("S3_BUCKET_NAME", "")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")


def test_dns_resolution(host: str) -> dict:
    """Tests DNS resolution for internal endpoints vs public domains."""
    try:
        ip_addresses = socket.gethostbyname_ex(host)[2]
        return {
            "host": host,
            "resolved_ips": ip_addresses,
            "status": "RESOLVED"
        }
    except Exception as e:
        return {
            "host": host,
            "resolved_ips": [],
            "status": "FAILED",
            "error": str(e)
        }


def test_public_internet_egress(target: str, port: int = 443, timeout: float = 2.0) -> dict:
    """
    Attempts connection to the public internet.
    EXPECTED RESULT: Connection timed out / unreachable (Zero Egress).
    """
    start_time = time.time()
    # Extract host if full URL is passed
    host = target
    if "://" in target:
        host = target.split("://")[1].split("/")[0]

    try:
        with socket.create_connection((host, port), timeout=timeout):
            latency_ms = (time.time() - start_time) * 1000
            return {
                "target": f"{host}:{port}",
                "egress_blocked": False,
                "status": "LEAK_DETECTED",
                "latency_ms": round(latency_ms, 2),
                "message": "CRITICAL: Outbound connection succeeded! Air-gap is broken."
            }
    except Exception as e:
        latency_ms = (time.time() - start_time) * 1000
        return {
            "target": f"{host}:{port}",
            "egress_blocked": True,
            "status": "SECURE_ZERO_EGRESS",
            "latency_ms": round(latency_ms, 2),
            "message": f"Verified: Outbound packet blocked as expected ({type(e).__name__})."
        }


def test_s3_privatelink_access(bucket_name: str) -> dict:
    """Tests S3 Gateway Endpoint read/write operations via AWS backbone."""
    if not bucket_name or not s3_client:
        return {"status": "SKIPPED", "message": "No S3 bucket specified or boto3 unavailable"}

    test_key = f"sentinel/probe-{int(time.time())}.json"
    payload = {
        "agent": "VPC-Lambda-Sentinel",
        "timestamp": time.time(),
        "environment": ENVIRONMENT,
        "mode": "AirGapped-VPC"
    }

    start_time = time.time()
    try:
        # Write test
        s3_client.put_object(
            Bucket=bucket_name,
            Key=test_key,
            Body=json.dumps(payload),
            ContentType="application/json"
        )
        # Read test
        get_res = s3_client.get_object(Bucket=bucket_name, Key=test_key)
        content = json.loads(get_res["Body"].read().decode("utf-8"))
        latency_ms = (time.time() - start_time) * 1000

        return {
            "status": "SUCCESS",
            "bucket": bucket_name,
            "key": test_key,
            "latency_ms": round(latency_ms, 2),
            "verified_payload": content.get("agent") == "VPC-Lambda-Sentinel"
        }
    except Exception as e:
        latency_ms = (time.time() - start_time) * 1000
        return {
            "status": "FAILED",
            "bucket": bucket_name,
            "error": f"{type(e).__name__}: {str(e)}",
            "latency_ms": round(latency_ms, 2)
        }


def lambda_handler(event, context):
    """Main execution handler for the Network Sentinel."""
    print("=== Starting Network Sentinel Zero-Egress Probe ===")

    # 1. Test Egress Leak (Must be BLOCKED)
    print("Testing public internet egress (1.1.1.1:443)...")
    public_probe = test_public_internet_egress("1.1.1.1", port=443, timeout=2.0)
    print("Testing public internet egress (google.com:443)...")
    dns_public_probe = test_public_internet_egress("google.com", port=443, timeout=2.0)

    # 2. Test Private DNS Resolution for VPC Endpoints
    region = os.environ.get("AWS_REGION", "us-east-1")
    print(f"Testing DNS resolution for ssm.{region}.amazonaws.com...")
    dns_ssm = test_dns_resolution(f"ssm.{region}.amazonaws.com")
    print(f"Testing DNS resolution for s3.{region}.amazonaws.com...")
    dns_s3 = test_dns_resolution(f"s3.{region}.amazonaws.com")

    # 3. Test S3 Gateway Endpoint Access
    print(f"Testing S3 Gateway Endpoint access on bucket '{S3_BUCKET_NAME}'...")
    s3_probe = test_s3_privatelink_access(S3_BUCKET_NAME)

    # Overall Compliance Evaluation
    zero_egress_verified = public_probe["egress_blocked"] and dns_public_probe["egress_blocked"]
    internal_aws_working = s3_probe.get("status") == "SUCCESS"
    compliance_passed = zero_egress_verified and internal_aws_working

    report = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "environment": ENVIRONMENT,
        "compliance": {
            "passed": compliance_passed,
            "zero_egress_enforced": zero_egress_verified,
            "privatelink_functional": internal_aws_working,
            "security_grade": "A+" if compliance_passed else "FAIL"
        },
        "egress_leak_tests": {
            "direct_ip": public_probe,
            "domain_name": dns_public_probe
        },
        "dns_resolution": {
            "ssm_endpoint": dns_ssm,
            "s3_endpoint": dns_s3
        },
        "aws_backbone_telemetry": {
            "s3_gateway": s3_probe
        }
    }

    print("Probe Report:")
    print(json.dumps(report, indent=2))

    return {
        "statusCode": 200 if compliance_passed else 500,
        "headers": {"Content-Type": "application/json"},
        "body": report
    }


if __name__ == "__main__":
    # Local CLI testing simulation
    print(json.dumps(lambda_handler({}, None), indent=2))
