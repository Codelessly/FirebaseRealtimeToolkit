# Google Cloud Monitoring for Firebase Analytics

This document outlines how to access Firebase Realtime Database and Cloud Firestore metrics through Google Cloud Monitoring for building dashboard analytics and reporting features.

## Overview

Firebase products are built on Google Cloud infrastructure, which means all underlying performance and usage metrics are available through **Google Cloud Monitoring** (formerly Stackdriver). This provides:

- Real-time metrics access via REST API
- Historical data querying with time ranges
- Programmatic access via client libraries (Python, Node.js, Go, Java)
- Command-line access via `gcloud` CLI
- Custom dashboards in Google Cloud Console

---

## Firebase Realtime Database Metrics

All Firebase Realtime Database metrics use the prefix: `firebasedatabase.googleapis.com/`

### Network Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `network/active_connections` | Gauge | Number of currently open realtime connections (WebSocket, long polling, SSE). Does not include REST requests. |
| `network/sent_bytes_count` | Counter | Total bytes sent from the database including protocol overhead |
| `network/sent_payload_bytes_count` | Counter | Bytes sent containing actual data payload |
| `network/sent_payload_and_protocol_bytes_count` | Counter | Combined payload and protocol bytes |
| `network/https_requests_count` | Counter | Number of SSL connection requests received |

**Labels for `network/https_requests_count`:**
- `reused_ssl_session` - Filter for requests that reused an existing SSL session ticket

### IO/Performance Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `io/database_load` | Gauge | Percentage of database capacity being used (0-100%) |

**Labels for `io/database_load` (operation types):**
- `admin` - Admin operations (setting rules, reading project metadata)
- `auth` - Authentication verification from service accounts or Firebase Auth
- `client_management` - Handling concurrent connections, disconnect operations
- `get_shallow` - REST GET with `shallow=true`
- `transaction` - Conditional REST requests or transaction operations
- `update` - Update operations or REST PATCH requests

### Storage Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `storage/total_bytes` | Gauge | Total size of data stored in the database |
| `storage/limit` | Gauge | Maximum storage allowed (based on plan) |
| `storage/disabled_for_overages` | Gauge | Indicates if database was disabled due to exceeded limits |

---

## Cloud Firestore Metrics

All Cloud Firestore metrics use the prefix: `firestore.googleapis.com/`

### Network/Connection Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `network/active_connections` | Gauge | Number of active connections from Mobile/Web SDKs |
| `network/snapshot_listeners` | Gauge | Number of snapshot listeners registered across all clients |

> **Note:** Each client has one connection, but may have multiple snapshot listeners.

### Document Operation Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `document/read_ops_count` | Counter | Number of successful document reads (queries or lookups) |
| `document/write_ops_count` | Counter | Number of successful document writes |
| `document/delete_ops_count` | Counter | Number of successful document deletes |

### API/Billing Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `api/billable_read_units` | Counter | Billable read units consumed |
| `api/billable_write_units` | Counter | Billable write units consumed |
| `api/billable_realtime_read_units` | Counter | Billable units from real-time updates |
| `api/request_latencies` | Distribution | Latency distribution across completed requests |
| `api/request_sizes` | Distribution | Request payload sizes in bytes |
| `api/response_sizes` | Distribution | Response payload sizes in bytes |
| `document/billable_managed_delete_write_units` | Counter | Billable writes from TTL deletes |

---

## Accessing Metrics via gcloud CLI

### Prerequisites

```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### List Available Metrics

```bash
# List all Firebase Realtime Database metrics
gcloud monitoring metrics-descriptors list \
  --project=YOUR_PROJECT_ID \
  --filter='metric.type=starts_with("firebasedatabase.googleapis.com/")'

# List all Firestore metrics
gcloud monitoring metrics-descriptors list \
  --project=YOUR_PROJECT_ID \
  --filter='metric.type=starts_with("firestore.googleapis.com/")'
```

### Query Time Series Data

```bash
# Get active connections for last hour
gcloud monitoring time-series read \
  --project=YOUR_PROJECT_ID \
  --filter='metric.type="firebasedatabase.googleapis.com/network/active_connections"' \
  --start-time=$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Get Firestore snapshot listeners
gcloud monitoring time-series read \
  --project=YOUR_PROJECT_ID \
  --filter='metric.type="firestore.googleapis.com/network/snapshot_listeners"' \
  --start-time=$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
```

---

## REST API Access

### Endpoint

```
GET https://monitoring.googleapis.com/v3/projects/{project_id}/timeSeries
```

### Authentication

```bash
# Get access token
ACCESS_TOKEN=$(gcloud auth print-access-token)
```

### Example: Fetch Active Connections

```bash
curl -X GET \
  "https://monitoring.googleapis.com/v3/projects/YOUR_PROJECT_ID/timeSeries?filter=metric.type%3D%22firebasedatabase.googleapis.com%2Fnetwork%2Factive_connections%22&interval.startTime=2024-01-01T00:00:00Z&interval.endTime=2024-01-01T23:59:59Z" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json"
```

### Example: Fetch Database Load by Operation Type

```bash
curl -X GET \
  "https://monitoring.googleapis.com/v3/projects/YOUR_PROJECT_ID/timeSeries?filter=metric.type%3D%22firebasedatabase.googleapis.com%2Fio%2Fdatabase_load%22&interval.startTime=2024-01-01T00:00:00Z&interval.endTime=2024-01-01T23:59:59Z&aggregation.alignmentPeriod=60s&aggregation.perSeriesAligner=ALIGN_MEAN&aggregation.groupByFields=metric.labels.type" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)"
```

### Query Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `filter` | Yes | Metric type filter (must specify exactly one metric type) |
| `interval.startTime` | Yes | Start time in RFC3339 format |
| `interval.endTime` | Yes | End time in RFC3339 format |
| `aggregation.alignmentPeriod` | No | Time period for aggregation (e.g., `60s`, `300s`) |
| `aggregation.perSeriesAligner` | No | Aggregation method: `ALIGN_MEAN`, `ALIGN_MAX`, `ALIGN_SUM`, etc. |
| `aggregation.groupByFields` | No | Group results by labels (e.g., `metric.labels.type`) |

---

## Python Client Library

### Installation

```bash
pip install google-cloud-monitoring
```

### List Metric Descriptors

```python
from google.cloud import monitoring_v3

def list_firebase_metrics(project_id: str):
    """List all Firebase-related metric descriptors."""
    client = monitoring_v3.MetricServiceClient()
    project_name = f"projects/{project_id}"

    # List RTDB metrics
    rtdb_filter = 'metric.type = starts_with("firebasedatabase.googleapis.com/")'
    for descriptor in client.list_metric_descriptors(
        name=project_name,
        filter_=rtdb_filter
    ):
        print(f"RTDB: {descriptor.type}")
        print(f"  Description: {descriptor.description}")
        print(f"  Kind: {descriptor.metric_kind.name}")
        print(f"  Value Type: {descriptor.value_type.name}")
        print()

    # List Firestore metrics
    firestore_filter = 'metric.type = starts_with("firestore.googleapis.com/")'
    for descriptor in client.list_metric_descriptors(
        name=project_name,
        filter_=firestore_filter
    ):
        print(f"Firestore: {descriptor.type}")
        print(f"  Description: {descriptor.description}")
        print()
```

### Query Time Series Data

```python
from google.cloud import monitoring_v3
from google.protobuf.timestamp_pb2 import Timestamp
from datetime import datetime, timedelta

def get_active_connections(project_id: str, hours_back: int = 1):
    """Get active connections time series data."""
    client = monitoring_v3.MetricServiceClient()
    project_name = f"projects/{project_id}"

    # Time interval
    now = datetime.utcnow()
    start_time = now - timedelta(hours=hours_back)

    interval = monitoring_v3.TimeInterval()
    interval.end_time.FromDatetime(now)
    interval.start_time.FromDatetime(start_time)

    # Query
    results = client.list_time_series(
        request={
            "name": project_name,
            "filter": 'metric.type = "firebasedatabase.googleapis.com/network/active_connections"',
            "interval": interval,
            "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
        }
    )

    for time_series in results:
        print(f"Resource: {time_series.resource.type}")
        for point in time_series.points:
            print(f"  {point.interval.end_time}: {point.value.int64_value} connections")

    return results

def get_snapshot_listeners(project_id: str, hours_back: int = 1):
    """Get Firestore snapshot listeners time series data."""
    client = monitoring_v3.MetricServiceClient()
    project_name = f"projects/{project_id}"

    now = datetime.utcnow()
    start_time = now - timedelta(hours=hours_back)

    interval = monitoring_v3.TimeInterval()
    interval.end_time.FromDatetime(now)
    interval.start_time.FromDatetime(start_time)

    results = client.list_time_series(
        request={
            "name": project_name,
            "filter": 'metric.type = "firestore.googleapis.com/network/snapshot_listeners"',
            "interval": interval,
            "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
        }
    )

    for time_series in results:
        for point in time_series.points:
            print(f"  {point.interval.end_time}: {point.value.int64_value} listeners")

    return results

def get_database_load_by_operation(project_id: str, hours_back: int = 1):
    """Get database load grouped by operation type."""
    client = monitoring_v3.MetricServiceClient()
    project_name = f"projects/{project_id}"

    now = datetime.utcnow()
    start_time = now - timedelta(hours=hours_back)

    interval = monitoring_v3.TimeInterval()
    interval.end_time.FromDatetime(now)
    interval.start_time.FromDatetime(start_time)

    # Aggregation to group by operation type
    aggregation = monitoring_v3.Aggregation()
    aggregation.alignment_period.seconds = 300  # 5 minutes
    aggregation.per_series_aligner = monitoring_v3.Aggregation.Aligner.ALIGN_MEAN
    aggregation.group_by_fields.append("metric.labels.type")

    results = client.list_time_series(
        request={
            "name": project_name,
            "filter": 'metric.type = "firebasedatabase.googleapis.com/io/database_load"',
            "interval": interval,
            "aggregation": aggregation,
            "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
        }
    )

    for time_series in results:
        op_type = time_series.metric.labels.get("type", "unknown")
        print(f"Operation Type: {op_type}")
        for point in time_series.points:
            print(f"  {point.interval.end_time}: {point.value.double_value:.2f}%")

    return results
```

### Complete Dashboard Metrics Class

```python
from google.cloud import monitoring_v3
from datetime import datetime, timedelta
from typing import Dict, List, Any

class FirebaseMetricsCollector:
    """Collect Firebase metrics from Google Cloud Monitoring."""

    def __init__(self, project_id: str):
        self.project_id = project_id
        self.project_name = f"projects/{project_id}"
        self.client = monitoring_v3.MetricServiceClient()

    def _create_interval(self, hours_back: int = 1) -> monitoring_v3.TimeInterval:
        """Create a time interval for queries."""
        now = datetime.utcnow()
        interval = monitoring_v3.TimeInterval()
        interval.end_time.FromDatetime(now)
        interval.start_time.FromDatetime(now - timedelta(hours=hours_back))
        return interval

    def get_rtdb_metrics(self, hours_back: int = 1) -> Dict[str, Any]:
        """Get all key RTDB metrics."""
        interval = self._create_interval(hours_back)

        metrics = {
            "active_connections": self._query_metric(
                "firebasedatabase.googleapis.com/network/active_connections",
                interval
            ),
            "database_load": self._query_metric(
                "firebasedatabase.googleapis.com/io/database_load",
                interval
            ),
            "storage_bytes": self._query_metric(
                "firebasedatabase.googleapis.com/storage/total_bytes",
                interval
            ),
            "sent_bytes": self._query_metric(
                "firebasedatabase.googleapis.com/network/sent_bytes_count",
                interval
            ),
        }
        return metrics

    def get_firestore_metrics(self, hours_back: int = 1) -> Dict[str, Any]:
        """Get all key Firestore metrics."""
        interval = self._create_interval(hours_back)

        metrics = {
            "active_connections": self._query_metric(
                "firestore.googleapis.com/network/active_connections",
                interval
            ),
            "snapshot_listeners": self._query_metric(
                "firestore.googleapis.com/network/snapshot_listeners",
                interval
            ),
            "document_reads": self._query_metric(
                "firestore.googleapis.com/document/read_ops_count",
                interval
            ),
            "document_writes": self._query_metric(
                "firestore.googleapis.com/document/write_ops_count",
                interval
            ),
        }
        return metrics

    def _query_metric(
        self,
        metric_type: str,
        interval: monitoring_v3.TimeInterval
    ) -> List[Dict]:
        """Query a single metric type."""
        try:
            results = self.client.list_time_series(
                request={
                    "name": self.project_name,
                    "filter": f'metric.type = "{metric_type}"',
                    "interval": interval,
                    "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
                }
            )

            data_points = []
            for time_series in results:
                for point in time_series.points:
                    value = (
                        point.value.int64_value or
                        point.value.double_value or
                        point.value.string_value
                    )
                    data_points.append({
                        "timestamp": point.interval.end_time.ToDatetime().isoformat(),
                        "value": value,
                        "labels": dict(time_series.metric.labels),
                    })
            return data_points
        except Exception as e:
            print(f"Error querying {metric_type}: {e}")
            return []
```

---

## Node.js/TypeScript Client Library

### Installation

```bash
npm install @google-cloud/monitoring
```

### Query Metrics

```typescript
import { MetricServiceClient } from '@google-cloud/monitoring';

interface MetricDataPoint {
  timestamp: string;
  value: number;
  labels: Record<string, string>;
}

class FirebaseMetrics {
  private client: MetricServiceClient;
  private projectName: string;

  constructor(projectId: string) {
    this.client = new MetricServiceClient();
    this.projectName = `projects/${projectId}`;
  }

  async getActiveConnections(hoursBack: number = 1): Promise<MetricDataPoint[]> {
    const now = new Date();
    const startTime = new Date(now.getTime() - hoursBack * 60 * 60 * 1000);

    const [timeSeries] = await this.client.listTimeSeries({
      name: this.projectName,
      filter: 'metric.type = "firebasedatabase.googleapis.com/network/active_connections"',
      interval: {
        startTime: { seconds: Math.floor(startTime.getTime() / 1000) },
        endTime: { seconds: Math.floor(now.getTime() / 1000) },
      },
      view: 'FULL',
    });

    const dataPoints: MetricDataPoint[] = [];
    for (const series of timeSeries) {
      for (const point of series.points || []) {
        dataPoints.push({
          timestamp: new Date(
            Number(point.interval?.endTime?.seconds) * 1000
          ).toISOString(),
          value: Number(point.value?.int64Value || point.value?.doubleValue || 0),
          labels: series.metric?.labels as Record<string, string> || {},
        });
      }
    }
    return dataPoints;
  }

  async getSnapshotListeners(hoursBack: number = 1): Promise<MetricDataPoint[]> {
    const now = new Date();
    const startTime = new Date(now.getTime() - hoursBack * 60 * 60 * 1000);

    const [timeSeries] = await this.client.listTimeSeries({
      name: this.projectName,
      filter: 'metric.type = "firestore.googleapis.com/network/snapshot_listeners"',
      interval: {
        startTime: { seconds: Math.floor(startTime.getTime() / 1000) },
        endTime: { seconds: Math.floor(now.getTime() / 1000) },
      },
      view: 'FULL',
    });

    const dataPoints: MetricDataPoint[] = [];
    for (const series of timeSeries) {
      for (const point of series.points || []) {
        dataPoints.push({
          timestamp: new Date(
            Number(point.interval?.endTime?.seconds) * 1000
          ).toISOString(),
          value: Number(point.value?.int64Value || 0),
          labels: series.metric?.labels as Record<string, string> || {},
        });
      }
    }
    return dataPoints;
  }

  async getDatabaseLoad(hoursBack: number = 1): Promise<MetricDataPoint[]> {
    const now = new Date();
    const startTime = new Date(now.getTime() - hoursBack * 60 * 60 * 1000);

    const [timeSeries] = await this.client.listTimeSeries({
      name: this.projectName,
      filter: 'metric.type = "firebasedatabase.googleapis.com/io/database_load"',
      interval: {
        startTime: { seconds: Math.floor(startTime.getTime() / 1000) },
        endTime: { seconds: Math.floor(now.getTime() / 1000) },
      },
      aggregation: {
        alignmentPeriod: { seconds: 300 },
        perSeriesAligner: 'ALIGN_MEAN',
        groupByFields: ['metric.labels.type'],
      },
      view: 'FULL',
    });

    const dataPoints: MetricDataPoint[] = [];
    for (const series of timeSeries) {
      for (const point of series.points || []) {
        dataPoints.push({
          timestamp: new Date(
            Number(point.interval?.endTime?.seconds) * 1000
          ).toISOString(),
          value: Number(point.value?.doubleValue || 0),
          labels: series.metric?.labels as Record<string, string> || {},
        });
      }
    }
    return dataPoints;
  }
}

// Usage
async function main() {
  const metrics = new FirebaseMetrics('your-project-id');

  const connections = await metrics.getActiveConnections(24);
  console.log('Active Connections:', connections);

  const listeners = await metrics.getSnapshotListeners(24);
  console.log('Snapshot Listeners:', listeners);

  const load = await metrics.getDatabaseLoad(24);
  console.log('Database Load by Operation:', load);
}
```

---

## Dart/Flutter Client (for Admin Dashboard)

For a Flutter-based admin dashboard, you'll need to call the REST API. Here's a Dart implementation:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseMetricsClient {
  final String projectId;
  final String Function() getAccessToken;

  FirebaseMetricsClient({
    required this.projectId,
    required this.getAccessToken,
  });

  static const _baseUrl = 'https://monitoring.googleapis.com/v3';

  Future<List<MetricDataPoint>> getActiveConnections({
    Duration lookback = const Duration(hours: 1),
  }) async {
    return _queryMetric(
      'firebasedatabase.googleapis.com/network/active_connections',
      lookback: lookback,
    );
  }

  Future<List<MetricDataPoint>> getSnapshotListeners({
    Duration lookback = const Duration(hours: 1),
  }) async {
    return _queryMetric(
      'firestore.googleapis.com/network/snapshot_listeners',
      lookback: lookback,
    );
  }

  Future<List<MetricDataPoint>> getDatabaseLoad({
    Duration lookback = const Duration(hours: 1),
  }) async {
    return _queryMetric(
      'firebasedatabase.googleapis.com/io/database_load',
      lookback: lookback,
    );
  }

  Future<List<MetricDataPoint>> getDocumentReads({
    Duration lookback = const Duration(hours: 1),
  }) async {
    return _queryMetric(
      'firestore.googleapis.com/document/read_ops_count',
      lookback: lookback,
    );
  }

  Future<List<MetricDataPoint>> _queryMetric(
    String metricType, {
    required Duration lookback,
  }) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(lookback);

    final filter = Uri.encodeComponent('metric.type = "$metricType"');
    final startTime = start.toIso8601String();
    final endTime = now.toIso8601String();

    final url = '$_baseUrl/projects/$projectId/timeSeries'
        '?filter=$filter'
        '&interval.startTime=$startTime'
        '&interval.endTime=$endTime';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${getAccessToken()}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch metrics: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final timeSeries = data['timeSeries'] as List<dynamic>? ?? [];

    final dataPoints = <MetricDataPoint>[];
    for (final series in timeSeries) {
      final labels = Map<String, String>.from(
        series['metric']['labels'] ?? {},
      );
      final points = series['points'] as List<dynamic>? ?? [];

      for (final point in points) {
        final interval = point['interval'] as Map<String, dynamic>;
        final value = point['value'] as Map<String, dynamic>;

        dataPoints.add(MetricDataPoint(
          timestamp: DateTime.parse(interval['endTime'] as String),
          value: _extractValue(value),
          labels: labels,
        ));
      }
    }

    return dataPoints;
  }

  double _extractValue(Map<String, dynamic> value) {
    if (value.containsKey('int64Value')) {
      return double.parse(value['int64Value'] as String);
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    return 0.0;
  }
}

class MetricDataPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, String> labels;

  MetricDataPoint({
    required this.timestamp,
    required this.value,
    required this.labels,
  });

  @override
  String toString() => 'MetricDataPoint($timestamp: $value, labels: $labels)';
}
```

---

## IAM Permissions Required

To access Cloud Monitoring metrics, the service account or user needs:

| Permission | Description |
|------------|-------------|
| `monitoring.timeSeries.list` | Read time series data |
| `monitoring.metricDescriptors.list` | List available metrics |

These permissions are included in the following predefined roles:
- `roles/monitoring.viewer` - Read-only access to monitoring data
- `roles/monitoring.editor` - Read/write access
- `roles/viewer` - Project viewer (includes monitoring read)
- `roles/editor` - Project editor

---

## Dashboard Integration Strategy

### Key Metrics for Real-Time Signaling Dashboard

| Dashboard Feature | Firebase RTDB Metric | Firestore Metric |
|-------------------|---------------------|------------------|
| **Active Users** | `network/active_connections` | `network/active_connections` |
| **Active Listeners** | N/A (use connection count) | `network/snapshot_listeners` |
| **Throughput** | `network/sent_bytes_count` | `api/request_sizes` + `api/response_sizes` |
| **Load** | `io/database_load` | `api/request_latencies` |
| **Storage** | `storage/total_bytes` | N/A (use Firestore usage API) |
| **Operations** | `io/database_load` (by type) | `document/read_ops_count`, `document/write_ops_count` |

### Polling Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Dashboard Polling Strategy                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Real-time metrics (connections, listeners):                │
│    • Poll every 60 seconds                                  │
│    • Cloud Monitoring samples every 1 minute                │
│                                                             │
│  Operational metrics (load, throughput):                    │
│    • Poll every 5 minutes                                   │
│    • Aggregate with ALIGN_MEAN or ALIGN_SUM                 │
│                                                             │
│  Historical/billing metrics:                                │
│    • Query on-demand or hourly                              │
│    • Use longer aggregation periods (1h, 1d)                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Caching Recommendations

```
┌──────────────────┬──────────────────┬─────────────────────┐
│ Metric Type      │ Cache Duration   │ Refresh Strategy    │
├──────────────────┼──────────────────┼─────────────────────┤
│ Active Conns     │ 30 seconds       │ Background refresh  │
│ Listeners        │ 30 seconds       │ Background refresh  │
│ Database Load    │ 1 minute         │ On-demand + cache   │
│ Throughput       │ 5 minutes        │ Periodic batch      │
│ Storage          │ 15 minutes       │ Periodic batch      │
│ Historical       │ 1 hour           │ On-demand           │
└──────────────────┴──────────────────┴─────────────────────┘
```

---

## Limitations and Considerations

1. **Metric Sampling Delay**: Cloud Monitoring metrics have a 1-4 minute delay from real-time
2. **Query Quotas**: Cloud Monitoring API has rate limits (read the [quotas documentation](https://cloud.google.com/monitoring/quotas))
3. **Data Retention**: Metrics are retained for 6 weeks at 1-minute resolution, longer at aggregated resolutions
4. **Cost**: Cloud Monitoring API calls are free up to a quota, then charged per API call

---

## References

- [Firebase RTDB Monitor Performance](https://firebase.google.com/docs/database/usage/monitor-performance)
- [Firebase RTDB Monitor Usage](https://firebase.google.com/docs/database/usage/monitor-usage)
- [Firestore Monitor Usage](https://firebase.google.com/docs/firestore/monitor-usage)
- [Cloud Monitoring API Reference](https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.timeSeries/list)
- [Cloud Monitoring Filters](https://cloud.google.com/monitoring/api/v3/filters)
- [GCP Metrics Overview](https://cloud.google.com/monitoring/api/metrics_gcp)
