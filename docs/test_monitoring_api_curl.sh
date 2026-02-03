#!/bin/bash
#
# Test Google Cloud Monitoring REST API using curl
# Project: autostoryboardapp
#
# Prerequisites:
#   1. Install gcloud CLI: https://cloud.google.com/sdk/docs/install
#   2. Run: gcloud auth login
#   3. Run: gcloud config set project autostoryboardapp
#

set -e

PROJECT_ID="autostoryboardapp"
BASE_URL="https://monitoring.googleapis.com/v3"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================================================="
echo "🧪 Google Cloud Monitoring REST API Test (curl)"
echo "=================================================================="
echo ""
echo "📋 Project ID: $PROJECT_ID"
echo "📅 Test Time: $(date -u '+%Y-%m-%d %H:%M:%S') UTC"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found${NC}"
    echo ""
    echo "Please install Google Cloud SDK:"
    echo "  macOS: brew install --cask google-cloud-sdk"
    echo "  Or visit: https://cloud.google.com/sdk/docs/install"
    echo ""
    echo "After installation:"
    echo "  gcloud auth login"
    echo "  gcloud config set project $PROJECT_ID"
    exit 1
fi

# Get access token
echo -e "${BLUE}🔐 Getting access token...${NC}"
ACCESS_TOKEN=$(gcloud auth print-access-token 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}❌ Failed to get access token${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

echo -e "${GREEN}✅ Authentication successful${NC}"
echo ""

# Function to make API request
make_request() {
    local url="$1"
    local description="$2"

    echo -e "${BLUE}📡 $description${NC}"
    echo "   URL: $url"
    echo ""

    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        "$url")

    http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_STATUS:/d')

    if [ "$http_status" -eq 200 ]; then
        echo -e "${GREEN}✅ Success (HTTP $http_status)${NC}"
        echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    else
        echo -e "${RED}❌ Failed (HTTP $http_status)${NC}"
        echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    fi
    echo ""
    echo "------------------------------------------------------------------"
    echo ""
}

# Calculate time range (last 24 hours)
END_TIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
START_TIME=$(date -u -v-24H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ')

echo "=================================================================="
echo "🔥 Test 1: List Firebase Realtime Database Metrics"
echo "=================================================================="
echo ""

FILTER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('metric.type = starts_with(\"firebasedatabase.googleapis.com/\")'))")
URL="$BASE_URL/projects/$PROJECT_ID/metricDescriptors?filter=$FILTER&pageSize=100"
make_request "$URL" "Listing RTDB metric descriptors"

echo "=================================================================="
echo "🔥 Test 2: Query Active Connections (Last 24 Hours)"
echo "=================================================================="
echo ""

FILTER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('metric.type = \"firebasedatabase.googleapis.com/network/active_connections\"'))")
URL="$BASE_URL/projects/$PROJECT_ID/timeSeries?filter=$FILTER&interval.startTime=$START_TIME&interval.endTime=$END_TIME"
make_request "$URL" "Querying active connections time series"

echo "=================================================================="
echo "🔥 Test 3: Query Database Load (Last 24 Hours)"
echo "=================================================================="
echo ""

FILTER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('metric.type = \"firebasedatabase.googleapis.com/io/database_load\"'))")
URL="$BASE_URL/projects/$PROJECT_ID/timeSeries?filter=$FILTER&interval.startTime=$START_TIME&interval.endTime=$END_TIME"
make_request "$URL" "Querying database load time series"

echo "=================================================================="
echo "🔥 Test 4: Query Storage Usage (Last 24 Hours)"
echo "=================================================================="
echo ""

FILTER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('metric.type = \"firebasedatabase.googleapis.com/storage/total_bytes\"'))")
URL="$BASE_URL/projects/$PROJECT_ID/timeSeries?filter=$FILTER&interval.startTime=$START_TIME&interval.endTime=$END_TIME"
make_request "$URL" "Querying storage usage time series"

echo "=================================================================="
echo "🔥 Test 5: List Firestore Metrics"
echo "=================================================================="
echo ""

FILTER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('metric.type = starts_with(\"firestore.googleapis.com/\")'))")
URL="$BASE_URL/projects/$PROJECT_ID/metricDescriptors?filter=$FILTER&pageSize=100"
make_request "$URL" "Listing Firestore metric descriptors"

echo "=================================================================="
echo "🔥 Test 6: Query Firestore Snapshot Listeners (Last 24 Hours)"
echo "=================================================================="
echo ""

FILTER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('metric.type = \"firestore.googleapis.com/network/snapshot_listeners\"'))")
URL="$BASE_URL/projects/$PROJECT_ID/timeSeries?filter=$FILTER&interval.startTime=$START_TIME&interval.endTime=$END_TIME"
make_request "$URL" "Querying Firestore snapshot listeners"

echo "=================================================================="
echo "🔥 Test 7: Aggregated Query - Database Load by Operation Type"
echo "=================================================================="
echo ""

FILTER=$(python3 -c "import urllib.parse; print(urllib.parse.quote('metric.type = \"firebasedatabase.googleapis.com/io/database_load\"'))")
URL="$BASE_URL/projects/$PROJECT_ID/timeSeries?filter=$FILTER&interval.startTime=$START_TIME&interval.endTime=$END_TIME&aggregation.alignmentPeriod=300s&aggregation.perSeriesAligner=ALIGN_MEAN&aggregation.groupByFields=metric.labels.type"
make_request "$URL" "Querying database load grouped by operation type"

echo "=================================================================="
echo "✅ All Tests Completed!"
echo "=================================================================="
