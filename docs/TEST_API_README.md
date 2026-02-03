# Google Cloud Monitoring API Testing

This directory contains test scripts to verify Google Cloud Monitoring REST API access for Firebase metrics from the `autostoryboardapp` project.

## Prerequisites

### 1. Install Google Cloud SDK

**macOS:**
```bash
brew install --cask google-cloud-sdk
```

**Or download from:**
https://cloud.google.com/sdk/docs/install

### 2. Authenticate

```bash
# Login to your Google account
gcloud auth login

# Set the project
gcloud config set project autostoryboardapp

# Verify authentication
gcloud auth print-access-token
```

## Test Scripts

### Option 1: Bash/curl Script (Recommended for Quick Testing)

```bash
./test_monitoring_api_curl.sh
```

**What it tests:**
- ✅ Lists all Firebase Realtime Database metrics
- ✅ Queries active connections (last 24 hours)
- ✅ Queries database load (last 24 hours)
- ✅ Queries storage usage (last 24 hours)
- ✅ Lists all Firestore metrics
- ✅ Queries Firestore snapshot listeners (last 24 hours)
- ✅ Aggregated query: database load by operation type

**Output:**
- Pretty-printed JSON responses
- HTTP status codes
- Color-coded success/failure indicators

### Option 2: Python Script (More Flexible)

```bash
python3 test_cloud_monitoring_api.py
```

**Features:**
- Comprehensive metric descriptor listing
- Time series queries with multiple data points
- Formatted output with labels and values
- Error handling and detailed diagnostics

## Expected Metrics

### Firebase Realtime Database

| Metric Type | Description |
|-------------|-------------|
| `firebasedatabase.googleapis.com/network/active_connections` | Current open connections |
| `firebasedatabase.googleapis.com/io/database_load` | Database load % (0-100) |
| `firebasedatabase.googleapis.com/storage/total_bytes` | Total storage used |
| `firebasedatabase.googleapis.com/network/sent_bytes_count` | Outbound bandwidth |

### Cloud Firestore

| Metric Type | Description |
|-------------|-------------|
| `firestore.googleapis.com/network/active_connections` | Active SDK connections |
| `firestore.googleapis.com/network/snapshot_listeners` | Registered listeners |
| `firestore.googleapis.com/document/read_ops_count` | Document reads |
| `firestore.googleapis.com/document/write_ops_count` | Document writes |

## Manual curl Examples

### Get Access Token

```bash
ACCESS_TOKEN=$(gcloud auth print-access-token)
```

### List RTDB Metrics

```bash
curl -X GET \
  "https://monitoring.googleapis.com/v3/projects/autostoryboardapp/metricDescriptors?filter=metric.type%20%3D%20starts_with(%22firebasedatabase.googleapis.com%2F%22)" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" | python3 -m json.tool
```

### Query Active Connections

```bash
START_TIME="2026-02-02T00:00:00Z"
END_TIME="2026-02-03T00:00:00Z"

curl -X GET \
  "https://monitoring.googleapis.com/v3/projects/autostoryboardapp/timeSeries?filter=metric.type%3D%22firebasedatabase.googleapis.com%2Fnetwork%2Factive_connections%22&interval.startTime=$START_TIME&interval.endTime=$END_TIME" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" | python3 -m json.tool
```

### Query with Aggregation

```bash
curl -X GET \
  "https://monitoring.googleapis.com/v3/projects/autostoryboardapp/timeSeries?filter=metric.type%3D%22firebasedatabase.googleapis.com%2Fio%2Fdatabase_load%22&interval.startTime=$START_TIME&interval.endTime=$END_TIME&aggregation.alignmentPeriod=300s&aggregation.perSeriesAligner=ALIGN_MEAN&aggregation.groupByFields=metric.labels.type" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" | python3 -m json.tool
```

## Troubleshooting

### "gcloud: command not found"

Install Google Cloud SDK:
```bash
brew install --cask google-cloud-sdk
# Then restart your terminal
```

### "403 Forbidden" or "Permission Denied"

Ensure you have the required IAM permissions:
- `monitoring.timeSeries.list`
- `monitoring.metricDescriptors.list`

These are included in roles:
- `roles/monitoring.viewer`
- `roles/viewer`

Check your permissions:
```bash
gcloud projects get-iam-policy autostoryboardapp --flatten="bindings[].members" --filter="bindings.members:user:YOUR_EMAIL"
```

### "No data available"

This is normal if:
- Firebase Realtime Database or Firestore is not actively used
- No connections or operations occurred in the queried time range
- The service is not enabled for the project

You can verify services are enabled:
```bash
gcloud services list --enabled --project=autostoryboardapp | grep -E "firebase|firestore"
```

### HTTP 401 Unauthorized

Your access token may have expired. Refresh it:
```bash
gcloud auth login
gcloud auth print-access-token
```

Access tokens expire after 1 hour.

## Understanding the Response

### Metric Descriptor Response

```json
{
  "metricDescriptors": [
    {
      "type": "firebasedatabase.googleapis.com/network/active_connections",
      "description": "Number of active connections",
      "metricKind": "GAUGE",
      "valueType": "INT64",
      "labels": [...]
    }
  ]
}
```

### Time Series Response

```json
{
  "timeSeries": [
    {
      "metric": {
        "type": "firebasedatabase.googleapis.com/network/active_connections",
        "labels": {}
      },
      "resource": {
        "type": "firebase_namespace",
        "labels": {
          "database_name": "autostoryboardapp-default-rtdb"
        }
      },
      "points": [
        {
          "interval": {
            "endTime": "2026-02-03T20:00:00Z"
          },
          "value": {
            "int64Value": "5"
          }
        }
      ]
    }
  ]
}
```

**Key fields:**
- `metric.type` - The metric being measured
- `metric.labels` - Additional context (e.g., operation type)
- `resource.labels` - Which Firebase resource
- `points[].value` - The actual measurement
- `points[].interval.endTime` - When it was measured

## Integration with Dashboard

Once you've verified the API works, you can integrate it into your dashboard:

1. **Server-side polling**: Query metrics every 60 seconds for real-time data
2. **Caching**: Cache responses for 30-60 seconds to reduce API calls
3. **Aggregation**: Use alignment periods (60s, 300s) for cleaner charts
4. **Error handling**: Handle 429 rate limits and 401 auth errors gracefully

See [GOOGLE_CLOUD_MONITORING.md](./docs/GOOGLE_CLOUD_MONITORING.md) for complete integration guide.

## Next Steps

1. ✅ Verify gcloud authentication
2. ✅ Run the test scripts
3. ✅ Confirm metrics are available
4. 🔄 Implement dashboard integration
5. 🔄 Add caching and polling strategy
6. 🔄 Build visualization components
