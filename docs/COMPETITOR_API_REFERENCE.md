# Competitor API Reference

This document provides detailed API interfaces for the major realtime messaging competitors that we aim to support as drop-in replacements.

---

## Table of Contents
1. [PubNub API](#1-pubnub-api)
2. [Pusher API](#2-pusher-api)
3. [Ably API](#3-ably-api)
4. [API Mapping Matrix](#4-api-mapping-matrix)

---

## 1. PubNub API

### 1.1 Client Initialization

```dart
// Dart SDK
import 'package:pubnub/pubnub.dart';

final pubnub = PubNub(
  defaultKeyset: Keyset(
    subscribeKey: 'sub-c-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    publishKey: 'pub-c-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    userId: UserId('my-unique-user-id'),
    // Optional parameters
    secretKey: 'sec-c-xxxxx', // Server-side only
    authKey: 'auth-token',    // Legacy auth
  ),
);
```

```javascript
// JavaScript SDK
const pubnub = new PubNub({
  subscribeKey: 'sub-c-xxx',
  publishKey: 'pub-c-xxx',
  userId: 'my-unique-user-id',
  // Optional
  secretKey: 'sec-c-xxx',
  cipherKey: 'my-cipher-key',
  authKey: 'auth-token',
  ssl: true,
  presenceTimeout: 300,
  heartbeatInterval: 30,
});
```

### 1.2 Publish API

#### publish()
```dart
// Basic publish
final result = await pubnub.publish('channel-name', {'text': 'Hello'});
print(result.timetoken); // 16234567890123456

// Full options
final result = await pubnub.publish(
  'channel-name',
  {'type': 'message', 'text': 'Hello', 'sender': 'user-123'},
  storeMessage: true,      // Store in Message Persistence
  sendByPost: false,       // Use POST instead of GET
  ttl: 60,                 // TTL in minutes (requires Message Persistence)
  meta: {                  // Message metadata (filterable)
    'lang': 'en',
    'priority': 'high',
  },
  customMessageType: 'chat-message', // 3-50 chars, alphanumeric
);
```

**Response:**
```dart
class PublishResult {
  final BigInt timetoken;    // Server timestamp (17-digit, 100ns resolution)
  final String description;  // "Sent" on success
}
```

**Constraints:**
- Max message size: 32 KiB (optimal < 1.8 KB)
- Channel name: alphanumeric, `-`, `_`, `.`, `:`, `=`
- Max channel name length: 92 characters

#### fire()
```dart
// Fire - bypasses Message Persistence and doesn't replicate
await pubnub.fire('channel-name', {'alert': 'urgent'});
```

#### signal()
```dart
// Signal - lightweight messages (64 bytes max by default)
await pubnub.signal('channel-name', 'typing');
```

### 1.3 Subscribe API

#### subscribe()
```dart
// Create subscription
final subscription = pubnub.subscribe(
  channels: {'channel-1', 'channel-2'},
  channelGroups: {'group-1'},
  withPresence: true,
  timetoken: BigInt.from(16234567890123456), // Resume from timetoken
);

// Message stream
subscription.messages.listen((envelope) {
  print(envelope.channel);        // Channel name
  print(envelope.content);        // Message payload
  print(envelope.timetoken);      // Publish timetoken
  print(envelope.publisher);      // Publisher UUID
  print(envelope.subscriptionPattern); // Subscription pattern (for wildcards)
  print(envelope.userMetadata);   // Message metadata
  print(envelope.customMessageType); // Custom message type
});

// Presence stream
subscription.presence.listen((event) {
  print(event.action);    // 'join', 'leave', 'timeout', 'state-change', 'interval'
  print(event.uuid);      // User ID
  print(event.channel);   // Channel name
  print(event.timestamp); // Event timestamp
  print(event.state);     // User state (if state-change)
  print(event.occupancy); // Current channel occupancy
});

// Signal stream
subscription.signals.listen((signal) {
  print(signal.content);
  print(signal.publisher);
});

// Message actions stream
subscription.messageActions.listen((action) {
  print(action.type);       // 'reaction', 'receipt', custom
  print(action.value);      // Action value
  print(action.messageTimetoken);
  print(action.actionTimetoken);
  print(action.uuid);
});

// File stream
subscription.files.listen((file) {
  print(file.id);
  print(file.name);
  print(file.url);
});

// Objects stream (App Context)
subscription.objects.listen((event) {
  print(event.type);  // 'uuid', 'channel', 'membership'
  print(event.event); // 'set', 'delete'
  print(event.data);
});

// Status stream
subscription.status.listen((status) {
  print(status.category); // PNConnectedCategory, PNDisconnectedCategory, etc.
});
```

**Status Categories:**
```dart
enum PNStatusCategory {
  PNConnectedCategory,
  PNReconnectedCategory,
  PNDisconnectedCategory,
  PNUnexpectedDisconnectCategory,
  PNAccessDeniedCategory,
  PNTimeoutCategory,
  PNNetworkIssuesCategory,
  PNBadRequestCategory,
}
```

#### Subscription Control
```dart
subscription.pause();    // Pause subscription
subscription.resume();   // Resume subscription
await subscription.cancel(); // Cancel subscription

// Unsubscribe from specific channels
pubnub.unsubscribe(channels: {'channel-1'});

// Unsubscribe from all
pubnub.unsubscribeAll();
```

### 1.4 Presence API

#### hereNow()
```dart
// Get who's on a channel
final result = await pubnub.hereNow(
  channels: {'channel-1', 'channel-2'},
  channelGroups: {'group-1'},
  includeState: true,
  includeUUIDs: true,
);

// Response
print(result.totalOccupancy);  // Total users across all channels
print(result.totalChannels);   // Number of channels

for (final channel in result.channels.values) {
  print(channel.channelName);
  print(channel.occupancy);
  for (final uuid in channel.uuids) {
    print(uuid.uuid);
    print(uuid.state); // User state if includeState=true
  }
}
```

#### whereNow()
```dart
// Get channels a user is on
final result = await pubnub.whereNow(uuid: 'user-123');
print(result.channels); // List of channel names
```

#### setState() / getState()
```dart
// Set user state
await pubnub.setState(
  channels: {'channel-1'},
  channelGroups: {'group-1'},
  state: {'mood': 'happy', 'status': 'active'},
);

// Get user state
final result = await pubnub.getState(
  channels: {'channel-1'},
  uuid: 'user-123',
);
print(result.channels['channel-1']); // State map
```

#### Presence Events
```dart
// Subscribe with presence
subscription.presence.listen((event) {
  switch (event.action) {
    case 'join':
      print('${event.uuid} joined ${event.channel}');
      break;
    case 'leave':
      print('${event.uuid} left ${event.channel}');
      break;
    case 'timeout':
      print('${event.uuid} timed out from ${event.channel}');
      break;
    case 'state-change':
      print('${event.uuid} state changed: ${event.state}');
      break;
    case 'interval':
      // Batched presence updates (high occupancy channels)
      print('Interval: join=${event.join}, leave=${event.leave}');
      if (event.hereNowRefresh) {
        // Should call hereNow() to get full list
      }
      break;
  }
});
```

### 1.5 Message Persistence (History)

#### fetchHistory()
```dart
final result = await pubnub.fetchHistory(
  channels: {'channel-1', 'channel-2'},
  count: 100,                    // Max per channel (100 single, 25 multi)
  start: startTimetoken,         // Exclusive start (newer)
  end: endTimetoken,             // Exclusive end (older)
  reverse: false,                // false=newest first, true=oldest first
  includeMessageActions: true,
  includeMeta: true,
  includeMessageType: true,
  includeUUID: true,
);

for (final channel in result.channels.entries) {
  print('Channel: ${channel.key}');
  for (final message in channel.value.messages) {
    print(message.content);      // Message payload
    print(message.timetoken);    // Publish timetoken
    print(message.uuid);         // Publisher
    print(message.meta);         // Metadata
    print(message.messageType);  // Message type
    print(message.actions);      // Message actions
  }
  print('Start: ${channel.value.startTimetoken}');
  print('End: ${channel.value.endTimetoken}');
}
```

#### messageCounts()
```dart
final result = await pubnub.messageCounts(
  channels: ['channel-1', 'channel-2'],
  channelTimetokens: [timetoken1, timetoken2], // One per channel
);
print(result.channels); // Map<String, int>
```

#### deleteMessages()
```dart
await pubnub.deleteMessages(
  channel: 'channel-1',
  start: startTimetoken,
  end: endTimetoken,
);
```

### 1.6 Access Manager v3

#### grantToken()
```dart
// Server-side only (requires secretKey)
final token = await pubnub.grantToken(
  ttl: 60, // Minutes (1-43200, i.e., up to 30 days)
  authorizedUserId: 'user-123',
  channels: {
    // Specific channels
    'channel-1': ChannelPermissions(
      read: true,
      write: true,
      manage: false,
      delete: false,
      get: true,
      update: true,
      join: true,
    ),
    // Pattern (regex)
    'channel-.*': ChannelPermissions(read: true),
  },
  channelGroups: {
    'group-1': ChannelGroupPermissions(
      read: true,
      manage: true,
    ),
  },
  uuids: {
    'user-.*': UUIDPermissions(
      get: true,
      update: false,
      delete: false,
    ),
  },
  meta: {'custom': 'data'}, // Embedded in token
);

print(token); // JWT-like token string
```

#### setToken() / parseToken()
```dart
// Client-side: set token for authentication
pubnub.setToken(token);

// Parse token to inspect permissions
final parsed = pubnub.parseToken(token);
print(parsed.ttl);
print(parsed.authorizedUserId);
print(parsed.resources);
print(parsed.patterns);
```

#### revokeToken()
```dart
// Server-side only
await pubnub.revokeToken(token);
```

### 1.7 Channel Groups

```dart
// Add channels to group
await pubnub.channelGroups.addChannels(
  group: 'my-group',
  channels: {'channel-1', 'channel-2', 'channel-3'},
);

// List channels in group
final result = await pubnub.channelGroups.listChannels(group: 'my-group');
print(result.channels);

// Remove channels from group
await pubnub.channelGroups.removeChannels(
  group: 'my-group',
  channels: {'channel-3'},
);

// Delete entire group
await pubnub.channelGroups.deleteGroup(group: 'my-group');

// List all groups
final groups = await pubnub.channelGroups.listGroups();
```

### 1.8 REST API Endpoints

```
# Publish
GET /publish/{pub_key}/{sub_key}/0/{channel}/0/{message}
POST /publish/{pub_key}/{sub_key}/0/{channel}/0

# Subscribe
GET /subscribe/{sub_key}/{channel}/0/{timetoken}
GET /v2/subscribe/{sub_key}/{channel}/0

# Presence
GET /v2/presence/sub-key/{sub_key}/channel/{channel}
GET /v2/presence/sub-key/{sub_key}/uuid/{uuid}

# History
GET /v2/history/sub-key/{sub_key}/channel/{channel}
GET /v3/history/sub-key/{sub_key}/channel/{channels}

# Channel Groups
GET /v1/channel-registration/sub-key/{sub_key}/channel-group/{group}
GET /v1/channel-registration/sub-key/{sub_key}/channel-group
POST /v1/channel-registration/sub-key/{sub_key}/channel-group/{group}
DELETE /v1/channel-registration/sub-key/{sub_key}/channel-group/{group}

# Access Manager
POST /v3/pam/{sub_key}/grant

# Time
GET /time/0
```

---

## 2. Pusher API

### 2.1 Client Initialization

```javascript
// JavaScript Client
const pusher = new Pusher('APP_KEY', {
  cluster: 'mt1',                    // Required
  forceTLS: true,                    // Default: true
  userAuthentication: {              // For user authentication
    endpoint: '/pusher/user-auth',
    transport: 'ajax',
  },
  channelAuthorization: {            // For private/presence channels
    endpoint: '/pusher/auth',
    transport: 'ajax',
  },
  enabledTransports: ['ws', 'wss'],  // WebSocket only
  disabledTransports: ['xhr_streaming', 'xhr_polling', 'sockjs'],
});

// Connection state
pusher.connection.bind('state_change', (states) => {
  console.log(states.previous, '->', states.current);
});

// States: initialized, connecting, connected, unavailable, failed, disconnected
```

```python
# Python Server
import pusher

pusher_client = pusher.Pusher(
  app_id='APP_ID',
  key='APP_KEY',
  secret='APP_SECRET',
  cluster='mt1',
  ssl=True
)
```

### 2.2 Channel Types

```
public-{name}           - No authentication required
private-{name}          - Requires authentication
private-encrypted-{name} - E2E encrypted (requires auth + encryption key)
presence-{name}         - Shows who's online (requires auth)
cache-{name}            - Caches last event (can be combined with above)
```

### 2.3 Server HTTP API

#### Trigger Events
```http
POST /apps/{app_id}/events
Content-Type: application/json
Authorization: (signature-based)

{
  "name": "event-name",
  "channel": "channel-name",
  "data": "{\"message\": \"hello\"}",
  "socket_id": "exclude-socket-id",  // Optional: exclude sender
  "info": "subscription_count,user_count"  // Optional: request info
}

Response:
{
  "channels": {
    "presence-channel": {
      "subscription_count": 45,
      "user_count": 40
    }
  }
}
```

#### Batch Trigger (up to 10 events)
```http
POST /apps/{app_id}/batch_events
Content-Type: application/json

{
  "batch": [
    {
      "channel": "channel-1",
      "name": "event-1",
      "data": "{\"msg\": \"hello\"}"
    },
    {
      "channel": "channel-2",
      "name": "event-2",
      "data": "{\"msg\": \"world\"}"
    }
  ]
}
```

#### Query Channels
```http
# List all occupied channels
GET /apps/{app_id}/channels?filter_by_prefix=presence-&info=user_count

Response:
{
  "channels": {
    "presence-chat": {
      "user_count": 42
    },
    "presence-lobby": {
      "user_count": 12
    }
  }
}

# Get single channel info
GET /apps/{app_id}/channels/{channel_name}?info=subscription_count,user_count

# Get users in presence channel
GET /apps/{app_id}/channels/{channel_name}/users

Response:
{
  "users": [
    {"id": "user-1"},
    {"id": "user-2"}
  ]
}
```

### 2.4 Client API

#### Subscribing
```javascript
// Public channel
const channel = pusher.subscribe('my-channel');
channel.bind('my-event', (data) => {
  console.log(data);
});

// Private channel (requires auth endpoint)
const privateChannel = pusher.subscribe('private-my-channel');

// Encrypted channel (requires auth + encryption master key)
const encryptedChannel = pusher.subscribe('private-encrypted-my-channel');

// Presence channel
const presenceChannel = pusher.subscribe('presence-my-channel');

// Cache channel (gets last cached event on subscribe)
const cacheChannel = pusher.subscribe('cache-my-channel');
```

#### Event Binding
```javascript
// Bind to specific event
channel.bind('event-name', callback);

// Bind to all events
channel.bind_global((eventName, data) => {
  console.log(eventName, data);
});

// Unbind
channel.unbind('event-name', callback);
channel.unbind('event-name'); // All handlers for event
channel.unbind();             // All handlers for channel

// Unsubscribe
pusher.unsubscribe('my-channel');
```

#### Presence Channel
```javascript
const presenceChannel = pusher.subscribe('presence-chat');

// Subscription succeeded - get all members
presenceChannel.bind('pusher:subscription_succeeded', (members) => {
  console.log('Total members:', members.count);

  members.each((member) => {
    console.log(member.id, member.info);
  });

  console.log('Me:', members.me.id, members.me.info);
});

// Member joined
presenceChannel.bind('pusher:member_added', (member) => {
  console.log('Joined:', member.id, member.info);
});

// Member left
presenceChannel.bind('pusher:member_removed', (member) => {
  console.log('Left:', member.id);
});
```

#### Client Events (Private/Presence only)
```javascript
// Trigger from client (must be enabled in dashboard)
// Event name must start with 'client-'
privateChannel.trigger('client-typing', { user: 'john' });
```

### 2.5 Authentication

#### Private Channel Auth (Server Response)
```json
{
  "auth": "APP_KEY:SIGNATURE"
}
```

**Signature Format:**
```
HMAC-SHA256(socket_id:channel_name, SECRET)
```

#### Presence Channel Auth (Server Response)
```json
{
  "auth": "APP_KEY:SIGNATURE",
  "channel_data": "{\"user_id\":\"123\",\"user_info\":{\"name\":\"John\"}}"
}
```

**Signature Format:**
```
HMAC-SHA256(socket_id:channel_name:channel_data, SECRET)
```

#### Encrypted Channel Auth (Server Response)
```json
{
  "auth": "APP_KEY:SIGNATURE",
  "shared_secret": "BASE64_ENCODED_SHARED_SECRET"
}
```

### 2.6 Webhooks

```json
// POST to your webhook URL
{
  "time_ms": 1327078148132,
  "events": [
    {
      "name": "channel_occupied",
      "channel": "my-channel"
    },
    {
      "name": "channel_vacated",
      "channel": "my-channel"
    },
    {
      "name": "member_added",
      "channel": "presence-my-channel",
      "user_id": "user-123"
    },
    {
      "name": "member_removed",
      "channel": "presence-my-channel",
      "user_id": "user-123"
    },
    {
      "name": "client_event",
      "channel": "private-my-channel",
      "event": "client-typing",
      "data": "{\"user\":\"john\"}",
      "socket_id": "123.456",
      "user_id": "user-123"
    },
    {
      "name": "cache_miss",
      "channel": "cache-my-channel"
    }
  ]
}

// Headers
X-Pusher-Key: APP_KEY
X-Pusher-Signature: HMAC-SHA256(body, SECRET)
```

### 2.7 Constraints

| Constraint | Value |
|------------|-------|
| Event data size | 10 KB |
| Channels per trigger | 1-100 |
| Event name length | 200 chars |
| Channel name length | 200 chars |
| Batch size | 10 events |
| Presence members | 100 (default), 10,000 (max) |
| Client event rate | 10/second per client |
| Message rate | Varies by plan |

---

## 3. Ably API

### 3.1 Client Initialization

```javascript
// Realtime client
const ably = new Ably.Realtime({
  key: 'API_KEY',               // or
  token: 'TOKEN_STRING',        // or
  authUrl: '/ably/auth',        // Token auth URL
  authMethod: 'POST',
  clientId: 'my-client-id',     // For presence
  echoMessages: false,          // Don't receive own messages
  recover: 'RECOVERY_KEY',      // Resume previous connection
  transports: ['web_socket'],
});

// REST client
const ablyRest = new Ably.Rest({ key: 'API_KEY' });

// Connection state
ably.connection.on('connected', () => console.log('Connected'));
ably.connection.on('disconnected', () => console.log('Disconnected'));
ably.connection.on('failed', (err) => console.log('Failed', err));
```

### 3.2 REST API Endpoints

#### Authentication
```http
# Request token
POST /keys/{keyName}/requestToken
Content-Type: application/json

{
  "keyName": "app.key",
  "timestamp": 1234567890,
  "capability": "{\"channel\":[\"publish\",\"subscribe\"]}",
  "clientId": "client-123",
  "ttl": 3600000
}

# Revoke tokens
POST /keys/{keyName}/revokeTokens
{
  "targets": [
    {"type": "clientId", "value": "client-123"},
    {"type": "revocationKey", "value": "key-123"}
  ]
}
```

#### Messages
```http
# Publish message
POST /channels/{channelId}/messages
Content-Type: application/json

{
  "name": "event-name",
  "data": {"message": "hello"},
  "id": "unique-id",           // For idempotency
  "clientId": "sender-id",
  "extras": {
    "push": {                  // Push notification
      "notification": {
        "title": "Hello",
        "body": "World"
      }
    }
  }
}

# Batch publish to multiple channels
POST /messages
{
  "channels": ["channel-1", "channel-2"],
  "messages": [
    {"name": "event", "data": "hello"}
  ]
}

# Get message history
GET /channels/{channelId}/messages?start=1234&end=5678&limit=100&direction=backwards

# Get specific message
GET /channels/{channelId}/messages/{serial}

# Update message
PATCH /channels/{channelId}/messages/{serial}
{"action": 1, "data": "updated content"}

# Delete message
PATCH /channels/{channelId}/messages/{serial}
{"action": 2}
```

#### Presence
```http
# Get presence members
GET /channels/{channelId}/presence

Response:
[
  {"clientId": "user-1", "data": {"status": "online"}},
  {"clientId": "user-2", "data": {"status": "away"}}
]

# Get presence history
GET /channels/{channelId}/presence/history?limit=100

# Batch presence query
GET /presence?channels=ch1,ch2,ch3
```

#### Channels
```http
# Get channel info
GET /channels/{channelId}

Response:
{
  "channelId": "my-channel",
  "status": {
    "isActive": true,
    "occupancy": {
      "metrics": {
        "connections": 5,
        "publishers": 2,
        "subscribers": 5,
        "presenceConnections": 3,
        "presenceMembers": 3,
        "presenceSubscribers": 5
      }
    }
  }
}

# Enumerate channels
GET /channels?prefix=chat-&limit=100
```

#### Push Notifications
```http
# Register device
POST /push/deviceRegistrations
{
  "id": "device-id",
  "platform": "ios",
  "formFactor": "phone",
  "push": {
    "recipient": {"transportType": "apns", "deviceToken": "TOKEN"}
  },
  "clientId": "user-123"
}

# Subscribe device to channel
POST /push/channelSubscriptions
{
  "channel": "push-channel",
  "deviceId": "device-id"
}

# Direct push
POST /push/publish
{
  "recipient": {"deviceId": "device-id"},
  "notification": {
    "title": "Hello",
    "body": "World"
  },
  "data": {"custom": "data"}
}

# Batch push (up to 10,000)
POST /push/batch/publish
{
  "items": [
    {"recipient": {"deviceId": "d1"}, "notification": {...}},
    {"recipient": {"clientId": "c1"}, "notification": {...}}
  ]
}
```

#### Statistics
```http
GET /stats?start=1234&end=5678&unit=hour&direction=backwards

Response:
{
  "items": [
    {
      "intervalId": "2024-01-01:00",
      "all": {
        "messages": {"count": 1234, "data": 56789},
        "presence": {"count": 100, "data": 5000}
      },
      "channels": {"opened": 10, "peak": 50, "mean": 25}
    }
  ]
}
```

### 3.3 Realtime Client API

```javascript
// Get channel
const channel = ably.channels.get('my-channel', {
  params: { rewind: '1' }, // Get last message on attach
  modes: ['PUBLISH', 'SUBSCRIBE', 'PRESENCE'],
});

// Subscribe
channel.subscribe('event-name', (message) => {
  console.log(message.name);       // Event name
  console.log(message.data);       // Payload
  console.log(message.id);         // Message ID
  console.log(message.clientId);   // Publisher
  console.log(message.timestamp);  // Server timestamp
  console.log(message.extras);     // Extra data
});

// Subscribe to all
channel.subscribe((message) => { });

// Publish
await channel.publish('event-name', { message: 'hello' });
await channel.publish([
  { name: 'event-1', data: 'hello' },
  { name: 'event-2', data: 'world' },
]);

// History
const history = await channel.history({ limit: 100 });
history.items.forEach(msg => console.log(msg));
const nextPage = await history.next(); // Pagination

// Presence
await channel.presence.enter({ status: 'online' });
await channel.presence.update({ status: 'away' });
await channel.presence.leave();

const members = await channel.presence.get();
members.forEach(member => {
  console.log(member.clientId, member.data);
});

channel.presence.subscribe('enter', (member) => { });
channel.presence.subscribe('leave', (member) => { });
channel.presence.subscribe('update', (member) => { });

const presenceHistory = await channel.presence.history();

// Unsubscribe
channel.unsubscribe('event-name');
channel.unsubscribe();
channel.presence.unsubscribe();

// Detach
await channel.detach();
```

### 3.4 Token Capabilities

```json
{
  "channel-name": ["publish", "subscribe", "presence", "history"],
  "channel-*": ["subscribe"],
  "private-*": ["publish", "subscribe"],
  "[meta]channel.lifecycle": ["subscribe"]
}
```

**Permissions:**
- `publish` - Publish messages
- `subscribe` - Subscribe to messages
- `presence` - Enter presence and subscribe to presence events
- `history` - Access message history
- `push-subscribe` - Subscribe to push on channel
- `push-admin` - Admin push operations

### 3.5 Constraints

| Constraint | Value |
|------------|-------|
| Message size | 64 KB (default), 256 KB (configurable) |
| Message name | 128 chars |
| Channel name | 128 chars |
| Presence data | 256 bytes |
| Presence members | 200 (default), 20,000 (with batching) |
| History retention | 24h (default), 72h (max) |
| Batch messages | 100 per request |
| Push batch | 10,000 per request |

---

## 4. API Mapping Matrix

### Core Operations Mapping

| Our API | PubNub | Pusher | Ably |
|---------|--------|--------|------|
| `publish(channel, message)` | `publish()` | `trigger()` | `channel.publish()` |
| `subscribe(channels)` | `subscribe()` | `subscribe()` | `channel.subscribe()` |
| `unsubscribe(channels)` | `unsubscribe()` | `unsubscribe()` | `channel.detach()` |
| `presence.enter()` | Auto on subscribe | Auto on subscribe | `presence.enter()` |
| `presence.leave()` | Auto on unsubscribe | Auto on unsubscribe | `presence.leave()` |
| `presence.get()` | `hereNow()` | `GET /channels/{ch}/users` | `presence.get()` |
| `history()` | `fetchHistory()` | - | `channel.history()` |
| `grantToken()` | `grantToken()` | Server auth endpoint | `requestToken()` |
| `setState()` | `setState()` | Via auth `user_info` | `presence.update()` |
| `channelInfo()` | - | `GET /channels/{ch}` | `GET /channels/{ch}` |

### Authentication Mapping

| Our API | PubNub | Pusher | Ably |
|---------|--------|--------|------|
| API Key | `subscribeKey` + `publishKey` | `APP_KEY` | `API_KEY` |
| Secret Key | `secretKey` | `APP_SECRET` | Key secret part |
| User Token | `setToken()` | Auth signature | Token/JWT |
| Channel Auth | Access Manager | `channelAuthorization` | Capabilities |

### Channel Mapping

| Our Channel Type | PubNub | Pusher | Ably |
|------------------|--------|--------|------|
| Public | `channel` | `channel` | `channel` |
| Private | `channel` + PAM | `private-channel` | `channel` + capability |
| Presence | `channel` + presence | `presence-channel` | `channel` + presence mode |
| Encrypted | `channel` + cipherKey | `private-encrypted-channel` | TLS + custom |

### Event Mapping

| Our Event | PubNub | Pusher | Ably |
|-----------|--------|--------|------|
| Message | `messages` stream | `bind(event)` | `subscribe(name)` |
| Presence Join | `action: 'join'` | `pusher:member_added` | `enter` |
| Presence Leave | `action: 'leave'` | `pusher:member_removed` | `leave` |
| Presence Update | `action: 'state-change'` | - | `update` |
| Connection Status | `status` stream | `connection.state_change` | `connection.on()` |

---

## Appendix: SDK Repository Links

### Official SDKs to Reference

**PubNub:**
- Dart: https://github.com/pubnub/dart
- JavaScript: https://github.com/pubnub/javascript
- Swift: https://github.com/pubnub/swift
- Kotlin: https://github.com/pubnub/kotlin
- Python: https://github.com/pubnub/python
- Go: https://github.com/pubnub/go

**Pusher:**
- JavaScript: https://github.com/pusher/pusher-js
- Swift: https://github.com/pusher/pusher-websocket-swift
- Java/Android: https://github.com/pusher/pusher-websocket-java
- Python (Server): https://github.com/pusher/pusher-http-python
- Node.js (Server): https://github.com/pusher/pusher-http-node

**Ably:**
- JavaScript: https://github.com/ably/ably-js
- Flutter/Dart: https://github.com/ably/ably-flutter
- Swift: https://github.com/ably/ably-cocoa
- Java/Android: https://github.com/ably/ably-java
- Python: https://github.com/ably/ably-python
- Go: https://github.com/ably/ably-go
