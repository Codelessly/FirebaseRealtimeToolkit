# Firebase Realtime SaaS Product Plan

**Project**: Transform FirebaseRealtimeToolkit into a drop-in replacement for PubNub, Pusher, and Ably
**Date**: February 3, 2026
**Status**: Planning Phase

---

## Executive Summary

This document outlines the plan to transform FirebaseRealtimeToolkit into a comprehensive real-time messaging SaaS product that can serve as a drop-in replacement for major competitors while leveraging Firebase infrastructure for reliability and cost efficiency.

### Current State
- Lightweight Dart library (~500 lines of core code)
- Firebase RTDB SSE streaming
- Firestore document listening via gRPC
- Cross-platform support (Dart VM, Flutter, Web)
- Basic authentication (Firebase Auth tokens, Service Account)

### Target State
- Full SaaS platform with multi-tenant support
- API compatibility layers for PubNub, Pusher, Ably
- Admin dashboard with analytics and monitoring
- SDKs for all major platforms
- Firebase-native security (Auth integration, Security Rules, custom tokens)

---

## Part 1: Competitor Analysis

### 1.1 Feature Comparison Matrix

| Feature | PubNub | Pusher | Ably | Our Target |
|---------|--------|--------|------|------------|
| **Core Messaging** |
| Publish/Subscribe | ✅ | ✅ | ✅ | ✅ P1 |
| Channels | ✅ | ✅ | ✅ | ✅ P1 |
| Channel Groups | ✅ | - | ✅ (namespaces) | ✅ P2 |
| Private Channels | ✅ | ✅ | ✅ | ✅ P1 |
| Presence | ✅ | ✅ | ✅ | ✅ P1 |
| Message History | ✅ | - | ✅ | ✅ P2 |
| **Security** |
| Firebase Auth Integration | - | - | - | ✅ P1 |
| Custom Channel Tokens | ✅ (PAM v3) | ✅ | ✅ | ✅ P1 |
| Firebase Security Rules | - | - | - | ✅ P1 |
| Rate Limiting | ✅ | ✅ | ✅ | ✅ P2 |
| Client-side Encryption | ✅ | ✅ | ✅ | ✅ P3 (optional) |
| **Dashboard** |
| Real-time Monitoring | ✅ | ✅ | ✅ | ✅ P1 |
| Analytics | ✅ | ✅ (Datadog) | ✅ | ✅ P2 |
| Debug Console | ✅ | ✅ | ✅ | ✅ P1 |
| Usage Reports | ✅ | ✅ | ✅ | ✅ P1 |

**Priority Legend**: P1 = Phase 1 (MVP), P2 = Phase 2 (Core), P3 = Phase 3 (Optional/Advanced)

---

### 1.2 Security Model (Firebase-Native)

Our security model leverages Firebase's native capabilities rather than replicating competitor approaches:

#### Authentication Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    Client Authentication                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: Firebase Auth (Identity)                              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ • User signs in via Firebase Auth (email, OAuth, anonymous) ││
│  │ • Receives Firebase ID Token (JWT)                          ││
│  │ • Token contains uid, email, custom claims                  ││
│  └─────────────────────────────────────────────────────────────┘│
│                              ▼                                   │
│  Layer 2: Channel Access Tokens (Authorization)                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ • Server validates Firebase ID Token                        ││
│  │ • Issues short-lived Channel Token with permissions:        ││
│  │   - channels: ['chat-*', 'private-user-{uid}']             ││
│  │   - permissions: {read: true, write: true, presence: true} ││
│  │   - ttl: 60 minutes                                         ││
│  │ • Client uses Channel Token for pub/sub operations          ││
│  └─────────────────────────────────────────────────────────────┘│
│                              ▼                                   │
│  Layer 3: Firebase Security Rules (Enforcement)                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ • RTDB Security Rules enforce channel access patterns       ││
│  │ • Rules validate token claims and channel permissions       ││
│  │ • Server-side enforcement (cannot be bypassed)              ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### Channel Token Structure

```dart
/// Channel access token (similar to PubNub PAM, but Firebase-native)
class ChannelToken {
  final String token;           // Signed JWT
  final String userId;          // Firebase Auth UID
  final int ttl;                // TTL in minutes (1-1440)
  final DateTime expiresAt;
  final ChannelPermissions permissions;
}

class ChannelPermissions {
  /// Specific channel grants
  final Map<String, ChannelGrant> channels;

  /// Pattern-based grants (e.g., 'chat-*', 'private-{userId}')
  final Map<String, ChannelGrant> patterns;
}

class ChannelGrant {
  final bool read;      // Subscribe to channel
  final bool write;     // Publish to channel
  final bool presence;  // Join presence, see who's online
  final bool history;   // Access message history
}
```

#### Token Grant API

```dart
// Server-side: Generate channel token
final token = await realtimeService.grantToken(
  // Authenticate with Firebase ID token first
  firebaseIdToken: userIdToken,

  // Token configuration
  ttl: 60, // minutes

  // Channel permissions
  channels: {
    'chat-general': ChannelGrant(read: true, write: true, presence: true),
    'announcements': ChannelGrant(read: true, write: false),
  },

  // Pattern permissions
  patterns: {
    'private-${userId}': ChannelGrant.all(),
    'chat-*': ChannelGrant(read: true, write: true),
  },
);

// Client-side: Use token
client.setToken(token);
```

#### Firebase Security Rules Integration

```javascript
// Firebase RTDB Security Rules
{
  "rules": {
    "apps": {
      "$appId": {
        "channels": {
          "$channelName": {
            // Messages can be written if user has valid channel token
            "messages": {
              ".write": "auth != null && root.child('tokens').child(auth.uid).child($channelName).child('write').val() === true",
              ".read": "auth != null && root.child('tokens').child(auth.uid).child($channelName).child('read').val() === true"
            },
            // Presence requires presence permission
            "presence": {
              ".write": "auth != null && root.child('tokens').child(auth.uid).child($channelName).child('presence').val() === true",
              ".read": "auth != null"
            }
          }
        }
      }
    }
  }
}
```

#### Comparison with Competitors

| Feature | PubNub PAM v3 | Pusher Auth | Ably Capabilities | Our Approach |
|---------|---------------|-------------|-------------------|--------------|
| Identity Provider | PubNub userId | Your server | Ably clientId | Firebase Auth |
| Token Format | Custom JWT | HMAC signature | Ably Token/JWT | Firebase Custom Token |
| Enforcement | PubNub servers | Pusher servers | Ably servers | Firebase Security Rules |
| Token TTL | 1-43200 min | Per-request | Configurable | 1-1440 min |
| Pattern Matching | Regex | Channel prefixes | Wildcards | Glob patterns |
| Revocation | API call | N/A | API call | Token expiry + Security Rules |

#### Advantages of Firebase-Native Security

1. **Single Identity Source**: Firebase Auth handles all user authentication
2. **Server-Side Enforcement**: Security Rules cannot be bypassed by clients
3. **No Additional Infrastructure**: Leverages existing Firebase services
4. **Custom Claims**: Extend Firebase tokens with role-based permissions
5. **Audit Trail**: Firebase provides built-in logging and monitoring
6. **Cost Efficiency**: No separate auth service to maintain

---

### 1.2 PubNub API Reference

#### Core Configuration
```dart
// PubNub SDK initialization
final client = PubNub(
  defaultKeyset: Keyset(
    subscribeKey: 'sub-xxxx',
    publishKey: 'pub-xxxx',
    userId: UserId('user-guid'),
    // Optional
    secretKey: 'sec-xxxx',        // Server-side only
    cipherKey: CipherKey('key'),  // E2E encryption
    authKey: 'auth-xxxx',         // Legacy auth
  ),
);
```

#### Publish API
```dart
// Basic publish
await client.publish('channel', message);

// Full options
await channel.publish(
  message,
  storeMessage: true,      // Store in history
  ttl: 60,                 // TTL in minutes
  meta: {'key': 'value'},  // Metadata
  customMessageType: 'chat', // Message type label
);

// Fire (no history, no subscribers response)
await client.fire('channel', message);

// Signal (lightweight, 64-byte max)
await client.signal('channel', 'typing');
```

#### Subscribe API
```dart
// Subscribe to channels
final subscription = client.subscribe(
  channels: {'chat-123', 'chat-456'},
  channelGroups: {'cg_user_42'},
  withPresence: true,
  timetoken: 16234567890000000, // Resume from timetoken
);

// Event streams
subscription.messages.listen((envelope) {
  final payload = envelope.content;
  final timetoken = envelope.timetoken;
  final publisher = envelope.uuid;
});

subscription.presence.listen((event) {
  // join, leave, timeout, state-change
});

subscription.signals.listen((signal) { });
subscription.messageActions.listen((action) { });
subscription.files.listen((file) { });
subscription.objects.listen((obj) { });

// Control
subscription.pause();
subscription.resume();
await subscription.cancel();
```

#### Presence API
```dart
// Here Now - who's on a channel
final result = await client.hereNow(
  channels: ['channel'],
  includeUUIDs: true,
  includeState: true,
);

// Where Now - where is a user
final result = await client.whereNow(uuid: 'user-123');

// Set/Get State
await client.setState(
  channels: ['channel'],
  state: {'mood': 'happy'},
);

final state = await client.getState(
  channels: ['channel'],
  uuid: 'user-123',
);
```

#### Message Persistence (History)
```dart
// Fetch history
final history = await client.fetchHistory(
  channels: ['channel'],
  count: 100,
  start: startTimetoken,
  end: endTimetoken,
  reverse: false,
  includeMessageActions: true,
  includeMeta: true,
);

// Message counts
final counts = await client.messageCounts(
  channels: ['ch1', 'ch2'],
  channelTimetokens: [timetoken1, timetoken2],
);

// Delete messages
await client.deleteMessages(
  channel: 'channel',
  start: startTimetoken,
  end: endTimetoken,
);
```

#### Access Manager v3
```dart
// Grant token (server-side)
final token = await client.grantToken(
  ttl: 60, // minutes
  authorizedUserId: 'user-123',
  channels: {
    'channel-1': PubNubResourcePermissions(read: true, write: true),
    'channel-*': PubNubResourcePermissions(read: true), // Pattern
  },
  channelGroups: {
    'cg-1': PubNubResourcePermissions(read: true, manage: true),
  },
);

// Set token (client-side)
client.setToken(token);

// Revoke token (server-side)
await client.revokeToken(token);
```

#### Channel Groups
```dart
// Add channels to group
await client.channelGroups.addChannels(
  group: 'cg_user_42',
  channels: ['ch1', 'ch2'],
);

// List channels in group
final channels = await client.channelGroups.listChannels(
  group: 'cg_user_42',
);

// Remove channels from group
await client.channelGroups.removeChannels(
  group: 'cg_user_42',
  channels: ['ch1'],
);

// Delete group
await client.channelGroups.deleteGroup(group: 'cg_user_42');
```

---

### 1.3 Pusher API Reference

#### Core Configuration
```dart
// Pusher initialization
final pusher = Pusher(
  appId: 'APP_ID',
  key: 'APP_KEY',
  secret: 'APP_SECRET',
  cluster: 'mt1',
  useTLS: true,
);
```

#### Channel Types
```
public-*       - Anyone can subscribe
private-*      - Requires authentication
private-encrypted-* - E2E encrypted
presence-*     - Shows who's online
cache-*        - Caches last message
```

#### Server API (HTTP)
```http
# Trigger event
POST /apps/{app_id}/events
{
  "name": "event-name",
  "channel": "channel-name",
  "data": "{\"message\": \"hello\"}"
}

# Trigger batch (up to 10)
POST /apps/{app_id}/batch_events
{
  "batch": [
    {"channel": "ch1", "name": "event", "data": "..."},
    {"channel": "ch2", "name": "event", "data": "..."}
  ]
}

# Query channels
GET /apps/{app_id}/channels
GET /apps/{app_id}/channels/{channel_name}
GET /apps/{app_id}/channels/{channel_name}/users

# Response attributes
?info=subscription_count,user_count
```

#### Client API
```javascript
// Connect
const pusher = new Pusher('app_key', { cluster: 'mt1' });

// Subscribe
const channel = pusher.subscribe('channel-name');

// Bind events
channel.bind('event-name', (data) => { });
channel.bind_global((eventName, data) => { });

// Presence
const presence = pusher.subscribe('presence-channel');
presence.bind('pusher:subscription_succeeded', (members) => { });
presence.bind('pusher:member_added', (member) => { });
presence.bind('pusher:member_removed', (member) => { });

// Unsubscribe
pusher.unsubscribe('channel-name');

// Disconnect
pusher.disconnect();
```

#### Webhooks
```json
// Events: channel_occupied, channel_vacated, member_added, member_removed
{
  "time_ms": 1234567890123,
  "events": [
    {
      "channel": "presence-channel",
      "name": "member_added",
      "user_id": "user123"
    }
  ]
}
```

---

### 1.4 Ably API Reference

#### Core Configuration
```dart
// Ably initialization
final ably = AblyRealtime(
  key: 'app-key:secret',
  // or
  token: 'token-string',
  clientId: 'user-123',
);
```

#### REST API Endpoints
```http
# Authentication
POST /keys/{keyName}/requestToken
POST /keys/{keyName}/revokeTokens

# Messages
POST /channels/{channelId}/messages
GET /channels/{channelId}/messages
GET /channels/{channelId}/messages/{serial}
PATCH /channels/{channelId}/messages/{serial}

# Presence
GET /channels/{channelId}/presence
GET /channels/{channelId}/presence/history

# Channels
GET /channels
GET /channels/{channelId}

# Push
POST /push/deviceRegistrations
POST /push/channelSubscriptions
POST /push/publish
POST /push/batch/publish

# Stats
GET /stats
GET /time

# Batch
POST /messages (batch publish to multiple channels)
GET /presence (batch query presence)
```

#### Realtime Client
```javascript
// Subscribe
const channel = realtime.channels.get('channel-name');
channel.subscribe('event', (message) => { });

// Publish
await channel.publish('event', { data: 'payload' });

// Presence
await channel.presence.enter({ status: 'online' });
const members = await channel.presence.get();
channel.presence.subscribe('enter', (member) => { });
channel.presence.subscribe('leave', (member) => { });

// History
const history = await channel.history({ limit: 100 });
```

#### Message Operations
```http
# Update message (action: 1)
PATCH /channels/{channelId}/messages/{serial}
{ "action": 1, "data": "updated content" }

# Delete message (action: 2)
PATCH /channels/{channelId}/messages/{serial}
{ "action": 2 }

# Append to message (action: 5)
PATCH /channels/{channelId}/messages/{serial}
{ "action": 5, "data": "appended content" }
```

---

## Part 2: Dashboard Features Analysis

### 2.1 PubNub Dashboard Features

#### Admin Portal Structure
```
├── Apps Management
│   ├── Create/Delete Apps
│   ├── Keysets (Subscribe, Publish, Secret keys)
│   └── Add-on Configuration
│       ├── Stream Controller (Channel Groups)
│       ├── Message Persistence
│       ├── Presence
│       ├── Access Manager
│       ├── Functions
│       └── Push Notifications
│
├── PubNub Insights
│   ├── Channels Dashboard
│   │   ├── Unique channels count
│   │   ├── Messages per channel
│   │   ├── Subscribers per channel
│   │   └── Active users per channel
│   │
│   ├── Messages Dashboard
│   │   ├── Total messages
│   │   ├── Messages by type
│   │   ├── Geographic distribution
│   │   └── Message size analytics
│   │
│   └── Users Dashboard
│       ├── Active users
│       ├── Geographic distribution
│       ├── Top message senders
│       └── User engagement metrics
│
├── Usage & Monitoring
│   ├── Billable Metrics
│   │   ├── MAU (Monthly Active Users)
│   │   ├── Message Actions
│   │   ├── Replicated Transactions
│   │   └── Storage usage
│   │
│   ├── Monitoring Metrics
│   │   ├── API calls by endpoint
│   │   ├── Client errors
│   │   ├── Unauthorized access attempts
│   │   └── Latency percentiles
│   │
│   └── Operational Dashboards
│       ├── Real-time performance
│       ├── Regional traffic
│       └── Outage monitoring
│
├── Functions Module
│   ├── Create/Edit Functions
│   ├── Event Handlers
│   │   ├── Before/After Publish
│   │   ├── After Presence
│   │   ├── On Request
│   │   └── On Interval
│   ├── Debug Console
│   └── Logs Export
│
└── Illuminate (Advanced Analytics)
    ├── Business Objects
    ├── Custom Metrics
    ├── Decision Rules
    └── Custom Dashboards
```

#### Key Metrics Tracked
- Messages sent/received
- Active channels
- Subscribers per channel
- Presence events (join/leave/timeout)
- API call volume
- Error rates
- Latency (p50, p95, p99)
- Geographic distribution
- SDK version distribution

---

### 2.2 Pusher Dashboard Features

```
├── App Overview
│   ├── Quick Stats
│   │   ├── Connections
│   │   ├── Messages
│   │   └── Peak concurrent
│   │
│   └── App Credentials
│       ├── App ID
│       ├── Key
│       ├── Secret
│       └── Cluster
│
├── Debug Console
│   ├── Real-time Event Log
│   │   ├── Connections open/close
│   │   ├── Subscriptions
│   │   ├── Channel occupy/vacate
│   │   ├── Messages received
│   │   └── Webhook status
│   │
│   ├── Filters
│   │   ├── Channel name
│   │   ├── Event name
│   │   ├── Log type
│   │   ├── Data content
│   │   └── Timestamp
│   │
│   └── Event Creator
│       ├── Trigger test events
│       └── Channel/event/data input
│
├── Webhooks Configuration
│   ├── Endpoint URL
│   ├── Event types
│   └── Signature verification
│
└── Datadog Integration
    ├── 19 metrics available
    ├── Connection rates
    ├── Message rates by type
    │   ├── Broadcast
    │   ├── Client Event
    │   ├── Presence
    │   ├── Webhook
    │   └── API
    └── Size statistics
        ├── Count
        ├── Median
        ├── Average
        ├── 95th percentile
        └── Maximum
```

---

### 2.3 Ably Dashboard Features

```
├── App Overview
│   ├── Connection count
│   ├── Channel count
│   ├── Message rate
│   └── Bandwidth usage
│
├── Inspectors
│   ├── Channel Inspector
│   │   ├── Attached connections
│   │   ├── Live messages
│   │   ├── Presence set
│   │   ├── Active rules/integrations
│   │   ├── Message rates
│   │   ├── Occupancy
│   │   └── Connection counts
│   │
│   └── Connection Inspector
│       ├── Active connections
│       ├── Attached channels
│       ├── Publish rate
│       ├── Geographic location
│       └── SDK information
│
├── Stats Tab
│   ├── Statistics Table
│   │   ├── Previous month
│   │   ├── Current month
│   │   └── Custom timeframes
│   │
│   └── Statistics Chart
│       ├── Time range selection
│       └── Multiple metrics overlay
│
├── Reports
│   ├── Message volumes
│   ├── Connection durations
│   ├── Channel durations
│   └── Traffic sources
│
├── Web CLI
│   ├── Publish messages
│   ├── Subscribe to channels
│   ├── Enter presence
│   └── App configuration
│
└── Integrations
    ├── Datadog export
    └── Custom webhooks
```

---

### 2.4 OneSignal Dashboard Features

```
├── Audience
│   ├── Total Subscriptions
│   ├── Subscription Sources
│   │   ├── iOS
│   │   ├── Android
│   │   ├── Web
│   │   ├── Email
│   │   └── SMS
│   │
│   ├── Segments
│   │   ├── Subscribed Users
│   │   ├── Engaged Users
│   │   └── Custom segments
│   │
│   └── User Browser
│       ├── Search users
│       ├── View profiles
│       └── Send test messages
│
├── Delivery
│   ├── Sent Messages
│   │   ├── Message list
│   │   ├── Delivery stats
│   │   ├── Open rates
│   │   └── Click rates
│   │
│   └── Automated Messages
│       ├── Journey builder
│       ├── Triggers
│       └── Templates
│
├── Analytics
│   ├── Engagement Trends
│   │   ├── Push performance
│   │   ├── Email performance
│   │   ├── SMS performance
│   │   └── In-app messages
│   │
│   ├── Confirmed Deliveries
│   │   ├── Device receipts
│   │   ├── CTR estimates
│   │   └── Platform breakdown
│   │
│   └── AI Insights (Early Access)
│       ├── Performance analysis
│       └── Recommendations
│
├── Outcomes
│   ├── Conversion tracking
│   ├── Revenue attribution
│   └── Custom events
│
└── Settings
    ├── Platform Configuration
    │   ├── iOS (APNS)
    │   ├── Android (FCM)
    │   └── Web Push
    │
    ├── API Keys
    └── Team management
```

---

## Part 3: Product Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Client Applications                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │   Web    │  │   iOS    │  │ Android  │  │  Flutter │  │  Server  │      │
│  │   SDK    │  │   SDK    │  │   SDK    │  │   SDK    │  │   SDK    │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
└───────┼─────────────┼─────────────┼─────────────┼─────────────┼────────────┘
        │             │             │             │             │
        ▼             ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        API Gateway / Load Balancer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ WebSocket    │  │    REST      │  │    SSE       │  │  Compat API  │    │
│  │   Endpoint   │  │   Endpoint   │  │   Endpoint   │  │   Endpoints  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                         (PubNub/Pusher/Ably)│
└─────────────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Core Services Layer                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Channel    │  │   Presence   │  │    Auth      │  │   Message    │    │
│  │   Manager    │  │   Service    │  │   Service    │  │   Router     │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                      │
│  │   History    │  │    Token     │  │  Analytics   │                      │
│  │   Service    │  │   Manager    │  │   Service    │                      │
│  └──────────────┘  └──────────────┘  └──────────────┘                      │
└─────────────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Firebase Infrastructure                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  Realtime    │  │  Firestore   │  │   Firebase   │  │   Cloud      │    │
│  │  Database    │  │   (metadata) │  │     Auth     │  │  Functions   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐                                        │
│  │   BigQuery   │  │    Cloud     │                                        │
│  │  (analytics) │  │    Run       │                                        │
│  └──────────────┘  └──────────────┘                                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Data Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Multi-Tenant Model                              │
└─────────────────────────────────────────────────────────────────────────────┘

Organizations
├── id: string
├── name: string
├── plan: 'free' | 'starter' | 'pro' | 'enterprise'
├── settings: OrganizationSettings
└── createdAt: timestamp

Apps (Projects/Keysets)
├── id: string
├── organizationId: string
├── name: string
├── subscribeKey: string (public)
├── publishKey: string (public)
├── secretKey: string (server-only)
├── firebaseProjectId: string
├── settings: AppSettings
│   ├── presenceEnabled: boolean
│   ├── historyEnabled: boolean
│   ├── historyRetention: '1d' | '7d' | '30d' | '1y' | 'unlimited'
│   ├── channelTokensEnabled: boolean
│   └── rateLimitingEnabled: boolean
└── quotas: Quotas

Channels
├── appId: string
├── name: string
├── type: 'public' | 'private' | 'presence' | 'encrypted'
├── metadata: Map<string, dynamic>
├── occupancy: number
├── lastMessageAt: timestamp
└── stats: ChannelStats

Users/Connections
├── appId: string
├── userId: string (client-provided)
├── connectionId: string (system-assigned)
├── state: Map<string, dynamic>
├── channels: List<string>
├── metadata: UserMetadata
├── connectedAt: timestamp
└── lastActiveAt: timestamp

Messages
├── id: string
├── appId: string
├── channel: string
├── timetoken: bigint (nanoseconds)
├── publisher: string
├── payload: dynamic
├── metadata: Map<string, dynamic>
├── messageType: string
├── actions: List<MessageAction>
└── ttl: timestamp (optional)

Channel Tokens (Access Control)
├── id: string
├── appId: string
├── tokenHash: string (SHA-256 hash for lookup)
├── firebaseUid: string (linked Firebase Auth user)
├── channels: Map<string, ChannelGrant>
├── patterns: Map<string, ChannelGrant>
├── ttl: number (minutes, 1-1440)
├── createdAt: timestamp
├── expiresAt: timestamp
└── revoked: boolean

ChannelGrant
├── read: boolean
├── write: boolean
├── presence: boolean
└── history: boolean

Presence Events
├── appId: string
├── channel: string
├── userId: string
├── action: 'join' | 'leave' | 'timeout' | 'state-change'
├── state: Map<string, dynamic>
├── timestamp: timestamp
└── connectionId: string
```

### 3.3 API Compatibility Layer Design

```dart
/// Abstract interface for pub/sub operations
/// Implementations will provide PubNub, Pusher, Ably compatibility

abstract class RealtimeClient {
  /// Initialize the client
  Future<void> initialize(ClientConfig config);

  /// Publish a message to a channel
  Future<PublishResult> publish(
    String channel,
    dynamic message, {
    Map<String, dynamic>? meta,
    bool store = true,
    int? ttl,
  });

  /// Subscribe to channels
  Subscription subscribe(
    List<String> channels, {
    List<String>? channelGroups,
    bool withPresence = false,
    BigInt? timetoken,
  });

  /// Get presence information
  Future<PresenceResult> hereNow(
    List<String> channels, {
    bool includeState = false,
    bool includeUUIDs = true,
  });

  /// Set user state
  Future<void> setState(
    List<String> channels,
    Map<String, dynamic> state,
  );

  /// Fetch message history
  Future<HistoryResult> history(
    String channel, {
    BigInt? start,
    BigInt? end,
    int count = 100,
    bool reverse = false,
  });

  /// Grant access token
  Future<String> grantToken(TokenGrant grant);

  /// Revoke access token
  Future<void> revokeToken(String token);

  /// Disconnect
  Future<void> disconnect();
}

/// PubNub compatibility implementation
class PubNubCompatClient implements RealtimeClient {
  // Maps PubNub API to our internal implementation
}

/// Pusher compatibility implementation
class PusherCompatClient implements RealtimeClient {
  // Maps Pusher API to our internal implementation
  // Handles channel prefixes (private-, presence-, etc.)
}

/// Ably compatibility implementation
class AblyCompatClient implements RealtimeClient {
  // Maps Ably API to our internal implementation
}
```

### 3.4 REST API Design

```yaml
# OpenAPI 3.0 Specification (abbreviated)

paths:
  # === Publish/Subscribe ===
  /v1/publish/{channel}:
    post:
      summary: Publish message to channel
      parameters:
        - name: channel
          in: path
          required: true
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PublishRequest'
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PublishResponse'

  /v1/subscribe:
    get:
      summary: Subscribe to channels (SSE)
      parameters:
        - name: channels
          in: query
          schema:
            type: array
        - name: channel_groups
          in: query
          schema:
            type: array
        - name: tt
          in: query
          description: Timetoken to resume from
          schema:
            type: string

  # === Presence ===
  /v1/presence/here-now/{channel}:
    get:
      summary: Get users present on channel

  /v1/presence/where-now/{uuid}:
    get:
      summary: Get channels user is present on

  /v1/presence/state/{channel}/{uuid}:
    get:
      summary: Get user state
    put:
      summary: Set user state

  # === History ===
  /v1/history/{channel}:
    get:
      summary: Fetch message history
      parameters:
        - name: start
          in: query
        - name: end
          in: query
        - name: count
          in: query
        - name: reverse
          in: query
    delete:
      summary: Delete messages from history

  # === Channel Groups ===
  /v1/channel-groups/{group}:
    get:
      summary: List channels in group
    post:
      summary: Add channels to group
    delete:
      summary: Delete group

  /v1/channel-groups/{group}/channels:
    post:
      summary: Add channels
    delete:
      summary: Remove channels

  # === Channel Tokens (Access Control) ===
  /v1/auth/token:
    post:
      summary: Generate channel access token
      description: Requires valid Firebase ID token in Authorization header
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                ttl:
                  type: integer
                  description: Token TTL in minutes (1-1440)
                channels:
                  type: object
                  description: Channel-specific permissions
                patterns:
                  type: object
                  description: Pattern-based permissions

  /v1/auth/token/validate:
    post:
      summary: Validate channel token

  /v1/auth/token/revoke:
    post:
      summary: Revoke channel token

  # === Analytics ===
  /v1/stats:
    get:
      summary: Get usage statistics

  /v1/stats/channels:
    get:
      summary: Get channel statistics

  /v1/stats/messages:
    get:
      summary: Get message statistics

  # === Compatibility Endpoints ===
  # PubNub-compatible
  /pubnub/publish/{pub_key}/{sub_key}/0/{channel}/0:
    get:
      summary: PubNub publish compatibility

  /pubnub/subscribe/{sub_key}/{channel}/0/{tt}:
    get:
      summary: PubNub subscribe compatibility

  # Pusher-compatible
  /pusher/apps/{app_id}/events:
    post:
      summary: Pusher trigger compatibility

  /pusher/apps/{app_id}/channels:
    get:
      summary: Pusher channels query compatibility

  # Ably-compatible
  /ably/channels/{channel}/messages:
    post:
      summary: Ably publish compatibility
    get:
      summary: Ably history compatibility
```

---

## Part 4: Implementation Phases

### Phase 1: MVP (Weeks 1-6)

**Goal**: Basic pub/sub functionality with Firebase-native authentication and simple dashboard

#### Core Features
- [ ] Multi-tenant organization/app management
- [ ] Subscribe/publish keys generation
- [ ] Basic publish/subscribe API
- [ ] Channel management (create, list, delete)
- [ ] WebSocket connection support
- [ ] SSE fallback support
- [ ] Basic presence (join/leave events)

#### Security (Firebase-Native)
- [ ] Firebase Auth integration for user identity
- [ ] Firebase ID token validation
- [ ] Basic channel token generation
- [ ] Firebase Security Rules templates
- [ ] Public vs private channel support

#### Dashboard MVP
- [ ] Organization/App management UI
- [ ] API keys display
- [ ] Firebase project linking
- [ ] Real-time connection count
- [ ] Basic message counter
- [ ] Debug console (message log)
- [ ] Simple event triggering tool

#### SDK (Dart/Flutter)
- [ ] Initialize with keys + Firebase Auth
- [ ] Connect/disconnect
- [ ] Subscribe to channels
- [ ] Publish messages
- [ ] Listen for messages
- [ ] Basic presence events
- [ ] Set/get channel token

#### Deliverables
- Working pub/sub system with Firebase Auth
- Web dashboard with basic monitoring
- Dart SDK with core functionality
- API documentation
- Firebase Security Rules templates

---

### Phase 2: Core Features (Weeks 7-12)

**Goal**: Feature parity with basic Pusher/PubNub usage

#### Messaging Features
- [ ] Private channels (authenticated)
- [ ] Presence channels (who's online)
- [ ] Channel groups/namespaces
- [ ] Message history/persistence
- [ ] Message TTL configuration
- [ ] Message metadata support
- [ ] Signal messages (lightweight)

#### Presence System
- [ ] Full presence API (hereNow, whereNow)
- [ ] User state management
- [ ] Presence timeout detection
- [ ] Presence event streaming

#### Security Enhancements
- [ ] Advanced channel token permissions
  - [ ] Resource-level permissions
  - [ ] Pattern-based permissions (glob: 'chat-*', 'private-{userId}')
  - [ ] Configurable TTL (1-1440 minutes)
  - [ ] Token revocation API
- [ ] Rate limiting per user/channel
- [ ] Connection quotas per app
- [ ] Audit logging

#### Dashboard V2
- [ ] Channel browser/inspector
- [ ] Connection inspector
- [ ] Presence visualization
- [ ] Usage metrics and charts
- [ ] Error monitoring
- [ ] Token management UI

#### SDKs
- [ ] JavaScript/TypeScript SDK
- [ ] iOS (Swift) SDK
- [ ] Android (Kotlin) SDK
- [ ] Enhanced Dart/Flutter SDK

---

### Phase 3: API Compatibility & Polish (Weeks 13-18)

**Goal**: Drop-in replacement capability and production readiness

#### API Compatibility Layers
- [ ] PubNub API compatibility
  - [ ] URL structure matching
  - [ ] Request/response format
  - [ ] SDK wrapper (pubnub-compat)
  - [ ] Migration guide
- [ ] Pusher API compatibility
  - [ ] Channel prefixes (private-, presence-)
  - [ ] Event format
  - [ ] SDK wrapper (pusher-compat)
  - [ ] Migration guide
- [ ] Ably API compatibility
  - [ ] REST endpoints
  - [ ] Realtime protocol
  - [ ] SDK wrapper (ably-compat)
  - [ ] Migration guide

#### Advanced Messaging
- [ ] Batch publish operations
- [ ] Message compression
- [ ] Message filtering (server-side)

#### Optional: Client-Side Encryption (P3)
- [ ] Encryption key management
- [ ] AES-256-GCM encryption
- [ ] Key rotation support
- [ ] SDK encryption helpers

#### Dashboard V3
- [ ] Advanced analytics
- [ ] Custom date range reports
- [ ] Usage forecasting
- [ ] Cost analysis by channel/user
- [ ] Team management with roles
- [ ] Audit logs

---

### Phase 4: Scale & Enterprise (Weeks 19-24)

**Goal**: Production hardening and enterprise features

#### Scaling & Performance
- [ ] Multi-region deployment
- [ ] Connection pooling optimization
- [ ] Message queue optimization
- [ ] CDN integration for static assets

#### Migration Tools
- [ ] Data migration scripts from competitors
- [ ] Parallel running mode (shadow traffic)
- [ ] Gradual traffic shifting
- [ ] Compatibility testing suite
- [ ] Automated migration validator

#### Enterprise Features
- [ ] SSO/SAML integration
- [ ] Advanced team permissions
- [ ] SLA monitoring
- [ ] Priority support tier
- [ ] Custom retention policies
- [ ] Dedicated infrastructure option

---

## Part 5: Dashboard Specification

### 5.1 Navigation Structure

```
┌─────────────────────────────────────────────────────────────────┐
│  Logo    [Organization ▼]                    [User ▼] [⚙️]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📊 Dashboard                                                    │
│  📱 Apps                                                         │
│    └─ [App Name]                                                │
│       ├─ Overview                                               │
│       ├─ Channels                                               │
│       ├─ Connections                                            │
│       ├─ Messages                                               │
│       ├─ Presence                                               │
│       ├─ History                                                │
│       ├─ Tokens                                                 │
│       └─ Settings                                               │
│  📈 Analytics                                                   │
│    ├─ Usage                                                     │
│    ├─ Performance                                               │
│    └─ Reports                                                   │
│  🔧 Debug Console                                               │
│  📝 Logs                                                        │
│  ⚙️ Settings                                                    │
│    ├─ Organization                                              │
│    ├─ Team                                                      │
│    ├─ Billing                                                   │
│    ├─ API Keys                                                  │
│    └─ Firebase Config                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Key Dashboard Pages

#### Overview Page
```
┌─────────────────────────────────────────────────────────────────┐
│ App: My Application                              [Time Range ▼] │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  1,234   │  │   567    │  │   89K    │  │  12.3ms  │        │
│  │Connections│ │ Channels │  │ Messages │  │ Latency  │        │
│  │  ▲ 12%   │  │  ▲ 5%   │  │  ▲ 23%  │  │  ▼ 8%   │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
│                                                                  │
│  ┌─────────────────────────────────────────────────────┐        │
│  │                                                      │        │
│  │           Messages Over Time (Chart)                 │        │
│  │                                                      │        │
│  └─────────────────────────────────────────────────────┘        │
│                                                                  │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │  Top Channels       │  │  Recent Activity    │               │
│  │  1. chat-general    │  │  • User joined      │               │
│  │  2. notifications   │  │  • Message sent     │               │
│  │  3. updates         │  │  • Channel created  │               │
│  └─────────────────────┘  └─────────────────────┘               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### Debug Console
```
┌─────────────────────────────────────────────────────────────────┐
│ Debug Console                    [Filter: ________] [▶️ Start]  │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Filters: [Channel ▼] [Event ▼] [Type ▼]    [Clear]         │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Time       │ Type    │ Channel      │ Event    │ Data       │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ 14:23:45   │ MSG     │ chat-123     │ message  │ {...}      │ │
│ │ 14:23:44   │ PRES    │ chat-123     │ join     │ user_456   │ │
│ │ 14:23:43   │ SUB     │ chat-123     │ subscribe│ user_456   │ │
│ │ 14:23:42   │ CONN    │ -            │ connect  │ conn_789   │ │
│ │ 14:23:40   │ MSG     │ chat-123     │ message  │ {...}      │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Event Creator                                                │ │
│ │ Channel: [____________]  Event: [____________]               │ │
│ │ Data: [                                          ]           │ │
│ │                                           [Send Event]       │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### Analytics Page
```
┌─────────────────────────────────────────────────────────────────┐
│ Analytics                        [Last 7 Days ▼] [Export CSV]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Tabs: [Messages] [Connections] [Channels] [Presence] [Errors]   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                                                              ││
│  │              Message Volume (Time Series Chart)              ││
│  │                                                              ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌────────────────────────┐  ┌────────────────────────┐         │
│  │  By Channel            │  │  By Region             │         │
│  │  ┌───────────────────┐ │  │  ┌───────────────────┐ │         │
│  │  │   (Pie Chart)     │ │  │  │   (World Map)     │ │         │
│  │  └───────────────────┘ │  │  └───────────────────┘ │         │
│  └────────────────────────┘  └────────────────────────┘         │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Detailed Breakdown                                           ││
│  │ ┌─────────────────────────────────────────────────────────┐ ││
│  │ │ Channel      │ Messages │ Avg Size │ Publishers │ Subs  │ ││
│  │ ├─────────────────────────────────────────────────────────┤ ││
│  │ │ chat-general │ 45,234   │ 256 B    │ 123        │ 1,234 │ ││
│  │ │ updates      │ 12,456   │ 1.2 KB   │ 5          │ 8,765 │ ││
│  │ └─────────────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Part 6: Technical Decisions

### 6.1 Technology Stack

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Backend Runtime** | Dart (dart_frog / shelf) | Consistent with SDK, excellent performance |
| **Alternative Backend** | Node.js / Go | Better ecosystem for web services |
| **Realtime Transport** | WebSockets + SSE | Standard, wide support |
| **Message Broker** | Firebase RTDB | Already integrated, real-time native |
| **Metadata Storage** | Firestore | Flexible queries for app/org data |
| **Cache** | Redis (optional) | Fast presence/state management at scale |
| **Auth** | Firebase Auth | Native integration, no extra infra |
| **Token Signing** | Firebase Custom Tokens | Leverages Firebase Auth infrastructure |
| **API Hosting** | Cloud Run | Serverless, auto-scaling |
| **Analytics** | BigQuery | Massive scale analytics |
| **Dashboard** | Flutter Web | Cross-platform consistency |
| **Alternative Dashboard** | React + TypeScript | Better web ecosystem |

### 6.2 Scaling Considerations

```
Estimated Capacity Planning:

Tier 1 (MVP):
- 10K concurrent connections
- 100K messages/day
- Single region

Tier 2 (Growth):
- 100K concurrent connections
- 10M messages/day
- Multi-region (US, EU)

Tier 3 (Scale):
- 1M+ concurrent connections
- 1B+ messages/day
- Global distribution
```

### 6.3 Pricing Model (Draft)

| Plan | Price | Connections | Messages | Features |
|------|-------|-------------|----------|----------|
| **Free** | $0 | 100 | 10K/mo | Basic pub/sub, 1 day history |
| **Starter** | $25/mo | 1,000 | 500K/mo | Presence, 7 day history |
| **Pro** | $99/mo | 10,000 | 5M/mo | All features, 30 day history |
| **Enterprise** | Custom | Unlimited | Custom | SLA, dedicated support |

---

## Part 7: Success Metrics

### 7.1 MVP Success Criteria
- [ ] Publish latency < 100ms (p99)
- [ ] Subscribe latency < 50ms (p99)
- [ ] 99.9% uptime
- [ ] Support 10K concurrent connections
- [ ] Dashboard loads in < 2 seconds
- [ ] SDK integration in < 30 minutes

### 7.2 Growth Metrics
- Monthly Active Apps
- Messages per Day
- Average Connection Duration
- API Compatibility Coverage
- Migration Success Rate
- Customer Retention Rate

---

## Part 8: Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Firebase costs scale unexpectedly | High | Medium | Implement quotas, optimize queries |
| WebSocket scaling limits | High | Low | Use Cloud Run with connection pooling |
| API compatibility gaps | Medium | High | Extensive testing, gradual rollout |
| Security vulnerabilities | High | Low | Regular audits, pen testing |
| Dashboard performance | Medium | Medium | Lazy loading, caching, pagination |

---

## Part 9: Next Steps

### Immediate Actions (This Week)
1. [ ] Review and finalize this plan with stakeholders
2. [ ] Set up project infrastructure (repo, CI/CD, environments)
3. [ ] Create detailed technical design for Phase 1
4. [ ] Begin SDK interface design
5. [ ] Prototype WebSocket server

### Research Tasks
1. [ ] Download and analyze PubNub Dart SDK source code
2. [ ] Download and analyze Pusher client libraries
3. [ ] Document exact API request/response formats
4. [ ] Create compatibility test suites
5. [ ] Benchmark Firebase RTDB at scale

---

## Appendix A: Competitor API Downloads

### PubNub SDK Sources
- Dart: https://github.com/pubnub/dart
- JavaScript: https://github.com/pubnub/javascript
- Swift: https://github.com/pubnub/swift
- Android: https://github.com/pubnub/kotlin

### Pusher SDK Sources
- JavaScript: https://github.com/pusher/pusher-js
- Swift: https://github.com/pusher/pusher-websocket-swift
- Android: https://github.com/pusher/pusher-websocket-java
- Server libraries: https://github.com/pusher

### Ably SDK Sources
- JavaScript: https://github.com/ably/ably-js
- Dart: https://github.com/ably/ably-flutter
- Swift: https://github.com/ably/ably-cocoa
- Android: https://github.com/ably/ably-java

---

## Appendix B: References

### Documentation Links
- [PubNub Docs](https://www.pubnub.com/docs/)
- [PubNub JavaScript API](https://www.pubnub.com/docs/sdks/javascript/api-reference/publish-and-subscribe)
- [PubNub Insights](https://www.pubnub.com/docs/pubnub-insights/basics)
- [PubNub Access Manager](https://www.pubnub.com/docs/general/security/access-control)
- [Pusher Channels Docs](https://pusher.com/docs/channels/)
- [Pusher Client API](https://pusher.com/docs/channels/using_channels/client-api-overview/)
- [Pusher HTTP API](https://pusher.com/docs/channels/server_api/http-api/)
- [Pusher Debug Console](https://docs.bird.com/pusher/channels/channels/troubleshooting/how-do-i-use-the-channels-debug-console-and-event-creator)
- [Ably Pub/Sub Docs](https://ably.com/docs/basics)
- [Ably REST API](https://ably.com/docs/api/rest-api)
- [Ably Dashboard](https://ably.com/blog/ably-dashboard-realtime-observability)

### Firebase Documentation
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [Firebase Custom Tokens](https://firebase.google.com/docs/auth/admin/create-custom-tokens)
- [Firebase Security Rules](https://firebase.google.com/docs/database/security)
- [Firebase RTDB](https://firebase.google.com/docs/database)
