# Ably Realtime - Detailed Pricing Analysis

## Overview

Ably is a realtime data delivery platform that provides pub/sub messaging, presence, and data stream solutions with guaranteed message delivery.

**Website**: https://ably.com/
**Pricing Page**: https://ably.com/pricing

---

## Pricing Models

Ably offers **two pricing models** - you can choose the one that fits your use case best:

1. **Pay Per Minute**: Based on connection minutes and channel minutes
2. **Pay Per MAU**: Based on Monthly Active Users

---

## Pay Per Minute Model

### Free Plan ($0/month)

- **Messages**: 6M/month
- **Connection minutes**: Included
- **Channel minutes**: Included
- **Concurrent connections**: 200 peak
- **Message throughput**: 500 msg/sec
- **Support**: Community forums

### Standard Plan ($29/month)

- **Base**: $29/month
- **Messages**: $2.50 per million (after free tier)
- **Connection minutes**: $1.00 per million minutes
- **Channel minutes**: $1.00 per million minutes
- **Data transfer**: $0.25/GiB
- **Concurrent connections**: 10K peak
- **Message throughput**: 2,500 msg/sec
- **Support**: Email support

### Pro Plan ($399/month)

- **Base**: $399/month
- **Messages**: $2.50 per million
- **Connection minutes**: $1.00 per million minutes
- **Channel minutes**: $1.00 per million minutes
- **Data transfer**: $0.25/GiB
- **Concurrent connections**: 50K peak
- **Message throughput**: 10K msg/sec
- **Support**: Priority support
- **SLA**: Available

### Enterprise Plan (Custom)

- **Base**: Custom pricing
- **Messages**: $2.50 per million (volume discounts available)
- **Connection minutes**: $1.00 per million minutes (discounts available)
- **Channel minutes**: $1.00 per million minutes (discounts available)
- **Concurrent connections**: Unlimited
- **Message throughput**: Unlimited
- **Support**: Dedicated support
- **SLA**: Custom
- **Volume discounts**: As low as $0.50/million messages

---

## Pay Per MAU Model (Alternative)

Ably also offers MAU-based pricing as an alternative. Custom pricing based on:
- Monthly Active Users
- Usage patterns
- Feature requirements

**Contact sales** for MAU-based quotes.

---

## Example Costs (Pay Per Minute Model)

### Small App (10K Users, 5M Messages/Month)

Assumptions:
- 5M messages/month
- ~100 concurrent connections
- 10 hour average connection time per user/month
- 100,000 connection minutes
- 500,000 channel minutes

**Cost breakdown**:
- Base: $29
- Messages: 0 (under 6M free)
- Connection minutes: $0.10
- Channel minutes: $0.50
- **Total**: **~$39/month**

### Medium App (50K Users, 50M Messages/Month)

Assumptions:
- 50M messages/month
- ~2,500 concurrent connections
- 10 hour average connection time per user/month
- 500,000 connection minutes
- 5,000,000 channel minutes

**Cost breakdown**:
- Base: $399 (Pro plan needed)
- Messages: (44M over free tier) × $2.50/M = $110
- Connection minutes: $0.50
- Channel minutes: $5
- **Total**: **~$509/month**

### Large App (200K Users, 500M Messages/Month)

Assumptions:
- 500M messages/month
- ~10,000 concurrent connections
- 10 hour average connection time per user/month
- 2,000,000 connection minutes
- 20,000,000 channel minutes

**Cost breakdown**:
- Base: $399 (Pro plan)
- Messages: (494M over free tier) × $2.50/M = $1,235
- Connection minutes: $2
- Channel minutes: $20
- **Total**: **~$1,634/month**

---

## Key Metrics Explained

### Connection Minutes
The total time users are connected to Ably across all channels.
- 1 user connected for 60 minutes = 60 connection minutes
- Charged at $1.00 per million connection minutes

### Channel Minutes
The total time users are subscribed to channels.
- 1 user on 5 channels for 10 minutes = 50 channel minutes
- Charged at $1.00 per million channel minutes

### Messages
All messages published and received.
- Charged at $2.50 per million messages (after free tier)
- Volume discounts available (as low as $0.50/M at enterprise scale)

### Data Transfer
Bandwidth used for message delivery.
- Charged at $0.25/GiB
- Typically small unless sending large payloads

---

## Features by Plan

| Feature | Free | Standard | Pro | Enterprise |
|---------|------|----------|-----|------------|
| **Messages/month** | 6M | Unlimited | Unlimited | Unlimited |
| **Peak connections** | 200 | 10K | 50K | Unlimited |
| **Message throughput** | 500/sec | 2.5K/sec | 10K/sec | Unlimited |
| **Data retention** | 24 hours | 24 hours | Flexible | Custom |
| **Support** | Community | Email | Priority | Dedicated |
| **SLA** | No | No | Yes | Custom |
| **Rate limits** | Yes | Yes | Higher | Custom |

---

## Advantages

1. ✅ **Guaranteed delivery**: Strong message delivery guarantees
2. ✅ **Global edge network**: Low latency worldwide
3. ✅ **Flexible pricing**: Choose per-minute or MAU model
4. ✅ **Transparent metrics**: Clear breakdown of costs
5. ✅ **Strong SDKs**: High-quality client libraries
6. ✅ **Protocol support**: MQTT, WebSockets, SSE, HTTP
7. ✅ **Volume discounts**: Significant savings at scale

---

## Disadvantages

1. ❌ **Complex pricing**: Multiple metrics to track
2. ❌ **Channel minute costs**: Can add up with many channels
3. ❌ **Connection minute costs**: Long-lived connections expensive
4. ❌ **High base cost**: $29-399/month minimum for Standard+
5. ❌ **Data transfer fees**: Additional $0.25/GiB charges
6. ❌ **Limited free tier**: Only 200 concurrent connections

---

## Comparison to Firebase + FirebaseRealtimeToolkit

| Metric | Ably (Pay Per Minute) | Firebase Toolkit |
|--------|----------------------|------------------|
| **Pricing Model** | Minutes + messages | Bandwidth only |
| **Small (10K users)** | $39/month | ~$5/month |
| **Medium (50K users)** | $509/month | ~$40/month |
| **Large (200K users)** | $1,634/month | ~$490/month |
| **Free Tier** | 6M messages, 200 connections | 10GB bandwidth |
| **Connection Limits** | 200-50K+ | 200K per RTDB |
| **Message Costs** | $2.50/million | Included in bandwidth |
| **Connection Costs** | $1.00/million minutes | $0 |

**Savings with Firebase Toolkit**: 85-92% for most use cases

---

## When to Choose Ably

- ✅ You need **guaranteed message delivery** with ordering
- ✅ You require **multi-protocol support** (MQTT, WebSockets, SSE)
- ✅ You need **strong enterprise SLAs**
- ✅ You want **flexible pricing** (per-minute or MAU)
- ✅ You need **global edge network** with presence
- ✅ You can afford $500-2,000+/month
- ✅ You need **message history** with flexible retention

## When to Choose Firebase Toolkit

- ✅ You want **the most cost-effective solution** (85-92% savings)
- ✅ You're willing to manage Firebase setup
- ✅ You prefer **simple bandwidth-based pricing**
- ✅ You don't need minute-level connection tracking
- ✅ You want **no per-message charges**
- ✅ You have **budget constraints**

---

## Notable Features

### Message Delivery Guarantees
- **At-least-once delivery**: Messages guaranteed to arrive
- **Ordering**: Messages delivered in order
- **Idempotency**: Duplicate detection

### Presence
- Track user online/offline status
- Per-channel presence
- Occupancy tracking

### Message History
- Query past messages
- Flexible retention periods (Pro+)
- Replay capability

### Integrations
- Webhooks
- Queue integrations (AWS SQS, Azure, Google)
- Firehose to analytics platforms

---

## Cost Optimization Tips

1. **Use MAU pricing** if users connect frequently
2. **Optimize connection time**: Close idle connections
3. **Reduce channel subscriptions**: Only subscribe to needed channels
4. **Batch messages**: Reduce message count
5. **Use volume discounts**: Negotiate at enterprise scale
6. **Monitor usage**: Track metrics to avoid overages

---

## Last Updated

February 3, 2026
