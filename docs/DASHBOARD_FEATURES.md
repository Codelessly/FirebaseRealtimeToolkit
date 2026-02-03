# Dashboard Features Specification

This document provides a detailed specification of the dashboard features required for the Firebase Realtime SaaS product, based on analysis of PubNub, Pusher, and Ably dashboards.

---

## Table of Contents
1. [Dashboard Overview](#1-dashboard-overview)
2. [PubNub Dashboard Features](#2-pubnub-dashboard-features)
3. [Pusher Dashboard Features](#3-pusher-dashboard-features)
4. [Ably Dashboard Features](#4-ably-dashboard-features)
5. [Our Dashboard Requirements](#5-our-dashboard-requirements)

---

## 1. Dashboard Overview

### Common Dashboard Patterns

All major competitors share these common dashboard patterns:

1. **Multi-tenant Organization Structure**
   - Organizations/Accounts contain multiple Apps/Projects
   - Each App has its own credentials (keys)
   - Team members can be invited with roles

2. **Real-time Monitoring**
   - Live connection counts
   - Message throughput
   - Active channels
   - Error rates

3. **Debug Tools**
   - Event log/console
   - Message inspection
   - Test event triggering

4. **Analytics & Reporting**
   - Historical data charts
   - Usage breakdowns
   - Export capabilities

5. **Configuration**
   - API key management
   - Feature toggles
   - Firebase project linking

---

## 2. PubNub Dashboard Features

### 2.1 Admin Portal Structure

```
PubNub Admin Portal
│
├── Account Level
│   ├── Account Settings
│   ├── Team Management
│   ├── Billing & Subscription
│   └── Support
│
├── App Level
│   ├── Overview Dashboard
│   │   ├── Quick stats (connections, messages, channels)
│   │   ├── Recent activity timeline
│   │   └── Health status indicators
│   │
│   ├── Keysets
│   │   ├── Subscribe Key (public)
│   │   ├── Publish Key (public)
│   │   ├── Secret Key (hidden, server-only)
│   │   ├── Cipher Key (for encryption)
│   │   └── Auth Key (legacy)
│   │
│   └── Add-ons Configuration
│       ├── Stream Controller
│       │   └── Channel Groups management
│       ├── Message Persistence
│       │   └── Retention settings (1d/7d/30d/1y/unlimited)
│       ├── Presence
│       │   ├── Enable/disable
│       │   ├── Announce Max (0-10000)
│       │   ├── Interval (seconds)
│       │   └── Presence Deltas
│       ├── Access Manager
│       │   ├── Enable/disable
│       │   └── Token settings
│       ├── Functions
│       │   └── Enable/disable
│       └── Push Notifications
│           ├── APNS settings
│           ├── FCM settings
│           └── Web Push settings
│
├── PubNub Insights
│   ├── Dashboards
│   │   ├── Channels Dashboard
│   │   │   ├── Unique channels over time
│   │   │   ├── Top channels by messages
│   │   │   ├── Top channels by subscribers
│   │   │   └── Channel growth trends
│   │   │
│   │   ├── Messages Dashboard
│   │   │   ├── Total messages over time
│   │   │   ├── Messages by channel
│   │   │   ├── Messages by type
│   │   │   ├── Message size distribution
│   │   │   └── Geographic distribution (map)
│   │   │
│   │   └── Users Dashboard
│   │       ├── Active users over time
│   │       ├── User geographic distribution
│   │       ├── Top message senders
│   │       ├── User engagement metrics
│   │       └── New vs returning users
│   │
│   └── Custom Dashboards (Premium)
│       └── Build your own dashboard with widgets
│
├── Usage & Monitoring
│   ├── Billable Metrics
│   │   ├── MAU (Monthly Active Users)
│   │   ├── Transactions
│   │   ├── Message Actions
│   │   ├── Replicated Transactions
│   │   ├── Edge Messages
│   │   └── Storage (GB)
│   │
│   ├── Monitoring Metrics
│   │   ├── Publish API calls
│   │   ├── Subscribe API calls
│   │   ├── Presence API calls
│   │   ├── History API calls
│   │   ├── Functions executions
│   │   ├── Client errors
│   │   └── Unauthorized access attempts
│   │
│   └── Operational Dashboards
│       ├── Real-time latency (p50, p95, p99)
│       ├── Regional performance
│       ├── Error rates
│       └── System health
│
├── Functions Module
│   ├── Functions List
│   │   ├── Name, type, status
│   │   ├── Create/Edit/Delete
│   │   └── Enable/Disable toggle
│   │
│   ├── Function Editor
│   │   ├── Code editor with syntax highlighting
│   │   ├── Event type selection
│   │   │   ├── Before Publish
│   │   │   ├── After Publish
│   │   │   ├── After Presence
│   │   │   ├── On Request
│   │   │   └── On Interval
│   │   ├── Channel pattern
│   │   ├── Test/Debug panel
│   │   └── Logs viewer
│   │
│   ├── Modules
│   │   ├── Pre-built modules library
│   │   └── Custom modules
│   │
│   └── KV Storage
│       └── View/Edit key-value pairs
│
└── Illuminate (Advanced)
    ├── Business Objects
    │   └── Define data entities
    ├── Decisions
    │   └── Create rules and actions
    └── Dashboards
        └── Custom analytics dashboards
```

### 2.2 Key Metrics Displayed

| Metric Category | Specific Metrics |
|-----------------|------------------|
| **Connections** | Total connections, Peak concurrent, Avg duration |
| **Messages** | Total sent, Messages/second, Avg size |
| **Channels** | Active channels, Peak channels, Avg occupancy |
| **Presence** | Join events, Leave events, Timeout events |
| **History** | Stored messages, Storage used (GB) |
| **Errors** | Client errors, Auth failures, Rate limits |

### 2.3 Time Ranges

- Last 24 hours (default)
- Last 7 days
- Last 30 days
- Custom range (date picker)
- Real-time (last 1 hour, live updating)

### 2.4 Data Retention

| Plan | Insights Retention |
|------|-------------------|
| Free | 90 days |
| Starter | 6 months |
| Pro | 12 months |
| Premium | Up to 3 years |

---

## 3. Pusher Dashboard Features

### 3.1 Dashboard Structure

```
Pusher Dashboard
│
├── Account Level
│   ├── Account Settings
│   ├── Team Management
│   └── Billing
│
├── Apps List
│   └── App Cards
│       ├── App name
│       ├── Cluster location
│       └── Quick stats
│
└── App Level
    ├── Overview
    │   ├── Getting Started Guide
    │   ├── Credentials Display
    │   │   ├── App ID
    │   │   ├── Key
    │   │   ├── Secret (click to reveal)
    │   │   └── Cluster
    │   └── Quick Links
    │       ├── Documentation
    │       └── Debug Console
    │
    ├── Debug Console
    │   ├── Connection Panel
    │   │   ├── Connection status
    │   │   └── Socket ID
    │   │
    │   ├── Event Log (real-time)
    │   │   ├── Timestamp
    │   │   ├── Event type (icon)
    │   │   │   ├── 🔌 Connection
    │   │   │   ├── 📺 Subscription
    │   │   │   ├── 📨 API Message
    │   │   │   ├── 👤 Presence
    │   │   │   ├── 🔔 Webhook
    │   │   │   └── ❌ Error
    │   │   ├── Channel name
    │   │   ├── Event name
    │   │   └── Data (expandable JSON)
    │   │
    │   ├── Filters
    │   │   ├── Search box
    │   │   ├── Channel filter
    │   │   ├── Event filter
    │   │   └── Type filter (checkboxes)
    │   │
    │   ├── Speed Control
    │   │   └── Slider: Fast ←→ Slow
    │   │
    │   └── Event Creator
    │       ├── Channel input
    │       ├── Event name input
    │       ├── Data (JSON editor)
    │       └── Send button
    │
    ├── App Settings
    │   ├── General
    │   │   ├── App name
    │   │   ├── Cluster (read-only)
    │   │   └── Max connections
    │   │
    │   ├── Features
    │   │   ├── Enable client events
    │   │   ├── Enable E2E encryption
    │   │   └── Cache channels
    │   │
    │   └── Danger Zone
    │       └── Delete app
    │
    ├── Webhooks
    │   ├── Webhook List
    │   │   ├── URL
    │   │   ├── Events (badges)
    │   │   └── Status
    │   │
    │   └── Add/Edit Webhook
    │       ├── Webhook URL
    │       ├── Event selection (checkboxes)
    │       │   ├── channel_occupied
    │       │   ├── channel_vacated
    │       │   ├── member_added
    │       │   ├── member_removed
    │       │   ├── client_event
    │       │   └── cache_miss
    │       └── Headers (optional)
    │
    ├── API Access
    │   ├── Credentials
    │   └── IP Whitelist
    │
    └── Usage Stats (via Datadog)
        ├── Connection metrics
        ├── Message metrics
        └── Size statistics
```

### 3.2 Debug Console Details

**Event Types and Icons:**
| Icon | Type | Description |
|------|------|-------------|
| 🔌 | connection | Client connected/disconnected |
| 📺 | subscription | Channel subscribe/unsubscribe |
| 📨 | api_message | Message from server API |
| 👤 | presence | Presence join/leave |
| 📤 | client_event | Client-triggered event |
| 🔔 | webhook | Webhook sent |
| ❌ | error | Error occurred |

**Log Entry Format:**
```
[14:23:45.123] [API_MSG] #chat-room | message | {"user": "john", "text": "hello"}
[14:23:44.892] [PRESENCE] #presence-chat | member_added | user_123
[14:23:44.567] [SUB] #chat-room | subscribe | socket_456
[14:23:44.234] [CONN] | connect | socket_456
```

### 3.3 Datadog Metrics (Premium)

| Metric Name | Type | Description |
|-------------|------|-------------|
| `pusher.connections.count` | Gauge | Current connections |
| `pusher.connections.rate` | Rate | Connection rate |
| `pusher.messages.count` | Counter | Message count |
| `pusher.messages.rate` | Rate | Messages per second |
| `pusher.messages.size.avg` | Gauge | Average message size |
| `pusher.messages.size.p95` | Gauge | 95th percentile size |
| `pusher.messages.size.max` | Gauge | Max message size |
| `pusher.messages.broadcast` | Counter | Broadcast messages |
| `pusher.messages.client_event` | Counter | Client events |
| `pusher.messages.presence` | Counter | Presence messages |
| `pusher.messages.webhook` | Counter | Webhook messages |
| `pusher.channels.occupied` | Gauge | Occupied channels |

---

## 4. Ably Dashboard Features

### 4.1 Dashboard Structure

```
Ably Dashboard
│
├── Account Level
│   ├── Account Settings
│   ├── Team Management
│   ├── Billing
│   └── Support
│
├── Apps List
│   └── App Cards with quick metrics
│
└── App Level
    ├── Overview
    │   ├── Summary Cards
    │   │   ├── Connections (live)
    │   │   ├── Channels (live)
    │   │   ├── Messages (live rate)
    │   │   └── Bandwidth (live)
    │   │
    │   └── Quick Links
    │       ├── API Keys
    │       ├── Integrations
    │       └── Documentation
    │
    ├── Inspectors
    │   ├── Channel Inspector
    │   │   ├── Channel Search
    │   │   ├── Channel List (sortable)
    │   │   │   ├── Name
    │   │   │   ├── Occupancy
    │   │   │   ├── Message Rate
    │   │   │   └── Status
    │   │   │
    │   │   └── Channel Detail Panel
    │   │       ├── Live Stats
    │   │       │   ├── Connections
    │   │       │   ├── Publishers
    │   │       │   ├── Subscribers
    │   │       │   └── Message rate
    │   │       │
    │   │       ├── Presence Members
    │   │       │   ├── Client ID
    │   │       │   ├── Connection ID
    │   │       │   └── Data
    │   │       │
    │   │       ├── Live Messages
    │   │       │   ├── Timestamp
    │   │       │   ├── Name
    │   │       │   ├── Publisher
    │   │       │   └── Data (expandable)
    │   │       │
    │   │       └── Channel Rules
    │   │           └── Active integrations
    │   │
    │   └── Connection Inspector
    │       ├── Connection List
    │       │   ├── Connection ID
    │       │   ├── Client ID
    │       │   ├── Duration
    │       │   ├── Location
    │       │   └── SDK
    │       │
    │       └── Connection Detail Panel
    │           ├── Connection Info
    │           │   ├── ID
    │           │   ├── Client ID
    │           │   ├── Connected at
    │           │   ├── IP / Location
    │           │   └── SDK version
    │           │
    │           ├── Attached Channels
    │           │   └── Channel list
    │           │
    │           └── Live Stats
    │               ├── Messages sent
    │               ├── Messages received
    │               └── Publish rate
    │
    ├── Stats
    │   ├── Summary Table
    │   │   ├── Time period columns
    │   │   │   ├── Previous month
    │   │   │   ├── Current month
    │   │   │   ├── Today
    │   │   │   └── This hour
    │   │   │
    │   │   └── Metric rows
    │   │       ├── Messages
    │   │       ├── Connections
    │   │       ├── Channels
    │   │       ├── API requests
    │   │       └── Bandwidth
    │   │
    │   └── Charts
    │       ├── Time Range Selector
    │       │   ├── Last hour
    │       │   ├── Last 24 hours
    │       │   ├── Last 7 days
    │       │   ├── Last 30 days
    │       │   └── Custom range
    │       │
    │       ├── Chart Types
    │       │   ├── Line chart (trends)
    │       │   ├── Bar chart (comparisons)
    │       │   └── Stacked area (composition)
    │       │
    │       └── Export Options
    │           ├── PNG image
    │           └── CSV data
    │
    ├── Reports
    │   ├── Usage Reports
    │   │   ├── Message volumes
    │   │   ├── Connection hours
    │   │   ├── Channel hours
    │   │   └── Bandwidth usage
    │   │
    │   └── Billing Reports
    │       └── Cost breakdown
    │
    ├── Web CLI (new)
    │   ├── Command input
    │   ├── Output display
    │   └── Commands:
    │       ├── publish <channel> <message>
    │       ├── subscribe <channel>
    │       ├── presence enter <channel>
    │       ├── history <channel>
    │       └── stats
    │
    ├── Settings
    │   ├── General
    │   │   ├── App name
    │   │   ├── App ID
    │   │   └── Status
    │   │
    │   ├── API Keys
    │   │   ├── Key list
    │   │   │   ├── Key name
    │   │   │   ├── Capabilities
    │   │   │   └── Status
    │   │   │
    │   │   └── Create Key
    │   │       ├── Name
    │   │       └── Capabilities (checkbox matrix)
    │   │
    │   ├── Rules (Integrations)
    │   │   ├── Rule list
    │   │   └── Create Rule
    │   │       ├── Source (channel pattern)
    │   │       ├── Request Type (message/presence)
    │   │       └── Target (webhook/queue/function)
    │   │
    │   ├── Namespaces
    │   │   └── Namespace configuration
    │   │       ├── Name
    │   │       ├── Message TTL
    │   │       ├── Persist messages
    │   │       └── Push enabled
    │   │
    │   └── Push Notifications
    │       ├── APNS Configuration
    │       ├── FCM Configuration
    │       └── Test Push
    │
    └── Logs
        ├── Search
        │   ├── Time range
        │   ├── Channel filter
        │   ├── Event type filter
        │   └── Full-text search
        │
        └── Log Entries
            ├── Timestamp
            ├── Type
            ├── Channel
            ├── Details (expandable)
            └── Export option
```

### 4.2 Channel Inspector Features

**Live Channel View:**
```
┌─────────────────────────────────────────────────────────────────┐
│ Channel: chat-room-123                              [Detach All]│
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Stats (live)                                                    │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│ │   42    │ │   15    │ │   38    │ │  125/s  │               │
│ │Connections│ │Publishers│ │Subscribers│ │Msg Rate │              │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘               │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Presence Members (38)                                   [Export]│
│ ┌─────────────────────────────────────────────────────────────┐│
│ │ Client ID     │ Connection │ Joined      │ Data             ││
│ ├─────────────────────────────────────────────────────────────┤│
│ │ user-123      │ conn-abc   │ 2 min ago   │ {"status":"..."}││
│ │ user-456      │ conn-def   │ 5 min ago   │ {"status":"..."}││
│ └─────────────────────────────────────────────────────────────┘│
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Live Messages                                  [Pause] [Clear] │
│ ┌─────────────────────────────────────────────────────────────┐│
│ │ 14:23:45 │ message  │ user-123 │ {"text": "Hello!"}        ││
│ │ 14:23:44 │ typing   │ user-456 │ true                       ││
│ │ 14:23:43 │ message  │ user-456 │ {"text": "Hi there"}       ││
│ └─────────────────────────────────────────────────────────────┘│
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Send Test Message                                               │
│ Event: [message      ] Data: [{"text": "test"}    ] [Send]     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Our Dashboard Requirements

### 5.1 MVP Dashboard (Phase 1)

```
MVP Dashboard Features
│
├── Auth & Organization
│   ├── Sign up / Sign in
│   ├── Create organization
│   └── Basic profile settings
│
├── App Management
│   ├── Create app
│   ├── Link Firebase project
│   ├── View app credentials
│   │   ├── Subscribe Key
│   │   ├── Publish Key
│   │   └── Secret Key (masked)
│   └── Delete app
│
├── Overview
│   ├── Live Stats Cards
│   │   ├── Active Connections
│   │   ├── Messages (24h)
│   │   └── Active Channels
│   │
│   └── Simple Activity Chart
│       └── Messages over time (24h)
│
├── Debug Console
│   ├── Live Event Log
│   │   ├── Timestamp
│   │   ├── Type (icon)
│   │   ├── Channel
│   │   ├── Event
│   │   └── Data (expandable)
│   │
│   ├── Basic Filters
│   │   ├── Channel name
│   │   └── Event type
│   │
│   └── Event Sender
│       ├── Channel input
│       ├── Event input
│       ├── Data (JSON)
│       └── Send button
│
└── Settings
    ├── App settings
    │   ├── Name
    │   └── Features toggle
    └── Danger zone
        └── Delete app
```

### 5.2 Core Dashboard (Phase 2)

```
Phase 2 Additions
│
├── Channel Browser
│   ├── Channel list with stats
│   ├── Channel detail view
│   │   ├── Live stats
│   │   ├── Presence members
│   │   └── Message stream
│   └── Channel search
│
├── Connection Browser
│   ├── Connection list
│   ├── Connection detail
│   │   ├── User info
│   │   ├── Channels subscribed
│   │   └── Activity stats
│   └── Connection search
│
├── Analytics
│   ├── Time range selector
│   ├── Charts
│   │   ├── Messages over time
│   │   ├── Connections over time
│   │   ├── Channels over time
│   │   └── Errors over time
│   │
│   └── Tables
│       ├── Top channels by messages
│       ├── Top channels by subscribers
│       └── Top users by messages
│
├── Channel Tokens UI
│   ├── Token generator
│   │   ├── Firebase user selector
│   │   ├── TTL selector (1-1440 min)
│   │   ├── Channel permissions
│   │   ├── Pattern permissions
│   │   └── Generate button
│   │
│   └── Token list
│       ├── Active tokens
│       ├── Expiration times
│       └── Revoke action
│
└── Usage & Billing
    ├── Usage metrics
    │   ├── MAU
    │   ├── Messages
    │   └── Storage
    │
    └── Current plan
        └── Upgrade option
```

### 5.3 Advanced Dashboard (Phase 3)

```
Phase 3 Additions
│
├── Advanced Analytics
│   ├── Custom date ranges
│   ├── Comparison views
│   ├── Geographic distribution
│   ├── Device/SDK breakdown
│   └── Export (CSV/PDF)
│
├── Team Management
│   ├── Invite members
│   ├── Role assignment
│   │   ├── Owner
│   │   ├── Admin
│   │   ├── Developer
│   │   └── Viewer
│   └── Activity audit log
│
├── Custom Dashboards
│   ├── Widget library
│   ├── Drag-and-drop layout
│   └── Save/Share dashboards
│
├── Optional: Client-Side Encryption
│   ├── Encryption key management
│   ├── Key rotation UI
│   └── Encryption status per channel
│
└── API Compatibility Tools
    ├── PubNub migration wizard
    ├── Pusher migration wizard
    ├── Ably migration wizard
    └── Compatibility test runner
```

### 5.4 Key UI Components

**Stats Card Component:**
```
┌─────────────────────┐
│ 🔌 Connections      │
│                     │
│     1,234           │
│   ▲ 12% vs yesterday│
│                     │
│   [Sparkline graph] │
└─────────────────────┘
```

**Event Log Entry:**
```
┌─────────────────────────────────────────────────────────────────┐
│ [14:23:45] [📨 MSG] #chat-room → message                        │
│                                                                  │
│   {                                                              │
│     "user": "john",                                              │
│     "text": "Hello everyone!",                                   │
│     "timestamp": 1234567890                                      │
│   }                                                              │
│                                                                  │
│                                              [Copy] [Replay]     │
└─────────────────────────────────────────────────────────────────┘
```

**Time Series Chart:**
```
┌─────────────────────────────────────────────────────────────────┐
│ Messages │ [1h] [24h] [7d] [30d] [Custom]              [Export] │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1000 ┤                    ╭───╮                                │
│       │                   ╭╯   ╰╮                               │
│   750 ┤              ╭───╯      ╰╮                              │
│       │             ╭╯           ╰─╮                            │
│   500 ┤        ╭───╯               ╰───╮                        │
│       │   ╭───╯                        ╰───╮                    │
│   250 ┤──╯                                  ╰───                │
│       │                                                          │
│     0 ┼──────────────────────────────────────────────────────   │
│        00  02  04  06  08  10  12  14  16  18  20  22  24      │
│                                                                  │
│ Avg: 523/min │ Peak: 1,024/min at 14:30 │ Total: 752,345       │
└─────────────────────────────────────────────────────────────────┘
```

### 5.5 Technical Implementation

| Component | Technology | Notes |
|-----------|------------|-------|
| **Framework** | Flutter Web | Cross-platform consistency |
| **Alternative** | React + TypeScript | Better web ecosystem |
| **State Management** | Riverpod / Redux | Predictable state |
| **Charts** | fl_chart / Recharts | Interactive charts |
| **Real-time** | WebSocket | Live updates |
| **API** | REST + gRPC | Hybrid approach |
| **Auth** | Firebase Auth | Existing integration |

### 5.6 Dashboard API Endpoints

```yaml
# Dashboard-specific APIs

/api/dashboard/stats:
  GET: Get overview statistics

/api/dashboard/stats/timeseries:
  GET: Get time-series data for charts
  params:
    - metric: messages|connections|channels|errors
    - interval: minute|hour|day
    - start: timestamp
    - end: timestamp

/api/dashboard/channels:
  GET: List channels with stats

/api/dashboard/channels/{name}:
  GET: Get channel details

/api/dashboard/channels/{name}/messages:
  GET: Get recent messages (for debug console)

/api/dashboard/channels/{name}/presence:
  GET: Get presence members

/api/dashboard/connections:
  GET: List active connections

/api/dashboard/connections/{id}:
  GET: Get connection details

/api/dashboard/events/stream:
  GET: SSE stream for debug console

/api/dashboard/events/send:
  POST: Send test event
```

---

## Summary

This specification provides a comprehensive view of competitor dashboard features and our implementation requirements. The phased approach allows us to:

1. **Phase 1 (MVP)**: Launch quickly with essential features
2. **Phase 2 (Core)**: Match basic Pusher/Ably functionality
3. **Phase 3 (Advanced)**: Compete with full PubNub/OneSignal feature set

Key differentiators to consider:
- **Better DX**: Cleaner UI, faster debug console
- **Lower cost**: Firebase infrastructure advantages
- **Open source**: SDK transparency
- **Modern tech**: Flutter/Dart ecosystem advantages
