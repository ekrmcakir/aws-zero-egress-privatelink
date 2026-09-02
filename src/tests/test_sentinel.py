import unittest
from unittest.mock import patch, MagicMock
import socket
import sys
import os

# Add lambda source dir to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../lambda")))
import sentinel


class TestSentinel(unittest.TestCase):

    def test_public_internet_egress_blocked(self):
        """Verify that when socket connection times out, it is correctly identified as SECURE_ZERO_EGRESS."""
        with patch("socket.create_connection", side_effect=socket.timeout("Connection timed out")):
            result = sentinel.test_public_internet_egress("1.1.1.1", timeout=0.1)
            self.assertTrue(result["egress_blocked"])
            self.assertEqual(result["status"], "SECURE_ZERO_EGRESS")

    def test_public_internet_egress_leaked(self):
        """Verify that if socket connection succeeds, it triggers LEAK_DETECTED alert."""
        mock_sock = MagicMock()
        mock_sock.__enter__.return_value = mock_sock
        with patch("socket.create_connection", return_value=mock_sock):
            result = sentinel.test_public_internet_egress("1.1.1.1", timeout=0.1)
            self.assertFalse(result["egress_blocked"])
            self.assertEqual(result["status"], "LEAK_DETECTED")

    def test_dns_resolution_success(self):
        """Verify DNS resolution parsing."""
        with patch("socket.gethostbyname_ex", return_value=("ssm.us-east-1.amazonaws.com", [], ["10.0.1.15"])):
            result = sentinel.test_dns_resolution("ssm.us-east-1.amazonaws.com")
            self.assertEqual(result["status"], "RESOLVED")
            self.assertIn("10.0.1.15", result["resolved_ips"])

    def test_s3_privatelink_access_success(self):
        """Verify S3 test when Put/Get operations succeed."""
        mock_s3 = MagicMock()
        mock_body = MagicMock()
        mock_body.read.return_value = b'{"agent": "VPC-Lambda-Sentinel"}'
        mock_s3.get_object.return_value = {"Body": mock_body}

        with patch.object(sentinel, "s3_client", mock_s3):
            res = sentinel.test_s3_privatelink_access("test-bucket")
            self.assertEqual(res["status"], "SUCCESS")
            self.assertTrue(res["verified_payload"])


if __name__ == "__main__":
    unittest.main()
