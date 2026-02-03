#!/usr/bin/env python3
"""
Test script for Google Cloud Monitoring REST API to fetch Firebase metrics.
Project: autostoryboardapp
"""

import json
import subprocess
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import urllib.parse
import urllib.request
import urllib.error


class CloudMonitoringAPI:
    """REST API client for Google Cloud Monitoring."""

    BASE_URL = "https://monitoring.googleapis.com/v3"

    def __init__(self, project_id: str):
        self.project_id = project_id
        self.project_name = f"projects/{project_id}"
        self.access_token = None

    def get_access_token(self) -> str:
        """Get access token using gcloud or service account."""
        if self.access_token:
            return self.access_token

        # Try to get access token from gcloud
        try:
            result = subprocess.run(
                ["gcloud", "auth", "print-access-token"],
                capture_output=True,
                text=True,
                check=True
            )
            self.access_token = result.stdout.strip()
            return self.access_token
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("❌ gcloud CLI not found or not authenticated")
            print("   Please run: gcloud auth login")
            sys.exit(1)

    def list_metric_descriptors(
        self,
        prefix: str
    ) -> List[Dict[str, Any]]:
        """List metric descriptors for a given prefix."""
        url = f"{self.BASE_URL}/{self.project_name}/metricDescriptors"
        filter_param = f'metric.type = starts_with("{prefix}")'

        params = {
            "filter": filter_param,
            "pageSize": 100
        }

        query_string = urllib.parse.urlencode(params)
        full_url = f"{url}?{query_string}"

        headers = {
            "Authorization": f"Bearer {self.get_access_token()}",
            "Content-Type": "application/json"
        }

        request = urllib.request.Request(full_url, headers=headers)

        try:
            with urllib.request.urlopen(request) as response:
                data = json.loads(response.read().decode())
                return data.get("metricDescriptors", [])
        except urllib.error.HTTPError as e:
            print(f"❌ HTTP Error {e.code}: {e.reason}")
            print(f"   Response: {e.read().decode()}")
            return []
        except Exception as e:
            print(f"❌ Error: {e}")
            return []

    def query_time_series(
        self,
        metric_type: str,
        hours_back: int = 1,
        alignment_period: Optional[int] = None,
        aligner: Optional[str] = None,
        group_by_fields: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Query time series data for a metric."""
        url = f"{self.BASE_URL}/{self.project_name}/timeSeries"

        now = datetime.utcnow()
        start_time = now - timedelta(hours=hours_back)

        params = {
            "filter": f'metric.type = "{metric_type}"',
            "interval.startTime": start_time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "interval.endTime": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        }

        if alignment_period:
            params["aggregation.alignmentPeriod"] = f"{alignment_period}s"
        if aligner:
            params["aggregation.perSeriesAligner"] = aligner
        if group_by_fields:
            for field in group_by_fields:
                params["aggregation.groupByFields"] = field

        query_string = urllib.parse.urlencode(params)
        full_url = f"{url}?{query_string}"

        headers = {
            "Authorization": f"Bearer {self.get_access_token()}",
            "Content-Type": "application/json"
        }

        request = urllib.request.Request(full_url, headers=headers)

        try:
            with urllib.request.urlopen(request) as response:
                data = json.loads(response.read().decode())
                return data.get("timeSeries", [])
        except urllib.error.HTTPError as e:
            error_body = e.read().decode()
            print(f"❌ HTTP Error {e.code}: {e.reason}")
            print(f"   Response: {error_body}")
            return []
        except Exception as e:
            print(f"❌ Error: {e}")
            return []


def format_metric_descriptor(descriptor: Dict[str, Any]) -> None:
    """Pretty print a metric descriptor."""
    print(f"\n  📊 {descriptor['type']}")
    print(f"     Description: {descriptor.get('description', 'N/A')}")
    print(f"     Kind: {descriptor.get('metricKind', 'N/A')}")
    print(f"     Value Type: {descriptor.get('valueType', 'N/A')}")

    labels = descriptor.get('labels', [])
    if labels:
        print(f"     Labels: {', '.join([l['key'] for l in labels])}")


def format_time_series(time_series_list: List[Dict[str, Any]]) -> None:
    """Pretty print time series data."""
    if not time_series_list:
        print("     ⚠️  No data points found")
        return

    for idx, series in enumerate(time_series_list):
        metric = series.get('metric', {})
        labels = metric.get('labels', {})
        points = series.get('points', [])

        print(f"\n     Series {idx + 1}:")
        if labels:
            print(f"       Labels: {json.dumps(labels, indent=10)}")

        print(f"       Data Points ({len(points)}):")
        for point in points[:5]:  # Show first 5 points
            interval = point.get('interval', {})
            value = point.get('value', {})

            # Extract value
            val = (
                value.get('int64Value') or
                value.get('doubleValue') or
                value.get('stringValue') or
                'N/A'
            )

            end_time = interval.get('endTime', 'N/A')
            print(f"         {end_time}: {val}")

        if len(points) > 5:
            print(f"         ... and {len(points) - 5} more points")


def test_firebase_rtdb_metrics(api: CloudMonitoringAPI):
    """Test Firebase Realtime Database metrics."""
    print("\n" + "="*70)
    print("🔥 Testing Firebase Realtime Database Metrics")
    print("="*70)

    # List available RTDB metrics
    print("\n1️⃣  Listing available RTDB metric descriptors...")
    descriptors = api.list_metric_descriptors("firebasedatabase.googleapis.com/")

    if descriptors:
        print(f"\n✅ Found {len(descriptors)} RTDB metrics:")
        for descriptor in descriptors:
            format_metric_descriptor(descriptor)
    else:
        print("\n⚠️  No RTDB metrics found (database may not be enabled)")
        return

    # Test specific metrics
    test_metrics = [
        ("firebasedatabase.googleapis.com/network/active_connections", "Active Connections"),
        ("firebasedatabase.googleapis.com/io/database_load", "Database Load"),
        ("firebasedatabase.googleapis.com/storage/total_bytes", "Storage Usage"),
        ("firebasedatabase.googleapis.com/network/sent_bytes_count", "Sent Bytes"),
    ]

    for metric_type, name in test_metrics:
        print(f"\n2️⃣  Querying {name} (last 24 hours)...")
        time_series = api.query_time_series(metric_type, hours_back=24)

        if time_series:
            print(f"   ✅ Found {len(time_series)} time series:")
            format_time_series(time_series)
        else:
            print(f"   ⚠️  No data available for {name}")


def test_firestore_metrics(api: CloudMonitoringAPI):
    """Test Cloud Firestore metrics."""
    print("\n" + "="*70)
    print("🔥 Testing Cloud Firestore Metrics")
    print("="*70)

    # List available Firestore metrics
    print("\n1️⃣  Listing available Firestore metric descriptors...")
    descriptors = api.list_metric_descriptors("firestore.googleapis.com/")

    if descriptors:
        print(f"\n✅ Found {len(descriptors)} Firestore metrics:")
        for descriptor in descriptors:
            format_metric_descriptor(descriptor)
    else:
        print("\n⚠️  No Firestore metrics found (Firestore may not be enabled)")
        return

    # Test specific metrics
    test_metrics = [
        ("firestore.googleapis.com/network/active_connections", "Active Connections"),
        ("firestore.googleapis.com/network/snapshot_listeners", "Snapshot Listeners"),
        ("firestore.googleapis.com/document/read_ops_count", "Document Reads"),
        ("firestore.googleapis.com/document/write_ops_count", "Document Writes"),
    ]

    for metric_type, name in test_metrics:
        print(f"\n2️⃣  Querying {name} (last 24 hours)...")
        time_series = api.query_time_series(metric_type, hours_back=24)

        if time_series:
            print(f"   ✅ Found {len(time_series)} time series:")
            format_time_series(time_series)
        else:
            print(f"   ⚠️  No data available for {name}")


def test_aggregated_query(api: CloudMonitoringAPI):
    """Test aggregated query with grouping."""
    print("\n" + "="*70)
    print("📈 Testing Aggregated Query (Database Load by Operation Type)")
    print("="*70)

    metric_type = "firebasedatabase.googleapis.com/io/database_load"

    print(f"\nQuerying {metric_type} with grouping by operation type...")
    time_series = api.query_time_series(
        metric_type,
        hours_back=24,
        alignment_period=300,  # 5 minutes
        aligner="ALIGN_MEAN",
        group_by_fields=["metric.labels.type"]
    )

    if time_series:
        print(f"✅ Found {len(time_series)} grouped time series:")
        format_time_series(time_series)
    else:
        print("⚠️  No data available")


def main():
    """Main test function."""
    project_id = "autostoryboardapp"

    print("="*70)
    print("🧪 Google Cloud Monitoring REST API Test")
    print("="*70)
    print(f"\n📋 Project ID: {project_id}")
    print(f"📅 Test Time: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC")

    # Initialize API client
    api = CloudMonitoringAPI(project_id)

    # Verify authentication
    print("\n🔐 Authenticating...")
    try:
        token = api.get_access_token()
        print(f"✅ Authentication successful (token: {token[:20]}...)")
    except Exception as e:
        print(f"❌ Authentication failed: {e}")
        sys.exit(1)

    # Run tests
    try:
        test_firebase_rtdb_metrics(api)
        test_firestore_metrics(api)
        test_aggregated_query(api)

        print("\n" + "="*70)
        print("✅ All tests completed!")
        print("="*70)

    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
