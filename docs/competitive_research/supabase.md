# Supabase - Detailed Pricing Analysis

## Overview

Supabase is an open-source Firebase alternative that bundles realtime database, authentication, storage, and edge functions into a unified platform.

**Website**: https://supabase.com/
**Pricing Page**: https://supabase.com/pricing

---

## Pricing Model

Supabase uses a **bundled platform pricing model** where realtime is included as part of the full backend platform. You cannot use Supabase Realtime standalone.

---

## Pricing Tiers

| Plan | Base Price/Month | Realtime Messages | Peak Connections | Additional Messages |
|------|------------------|-------------------|------------------|---------------------|
| **Free** | **$0** | 2M/month | 200 | N/A (hard limit) |
| **Pro** | **$25+** | 5M/month | 500 | $2.50/million |
| **Team** | **$599+** | 5M/month | 500 | $2.50/million |
| **Enterprise** | **Custom** | Custom | Custom | Custom |

---

## Plan Details

### Free Plan ($0/month)

**Realtime**:
- 2M messages/month (hard limit)
- 200 peak concurrent connections
- Basic PostgreSQL broadcasting

**Database**:
- 500MB database space
- Unlimited API requests
- 2GB file storage
- 50MB file upload limit

**Authentication**:
- 50,000 Monthly Active Users
- Social OAuth providers

**Edge Functions**:
- 500K function invocations
- 1GB function execution

**Support**:
- Community support only

**Limitations**:
- Paused after 7 days of inactivity
- Cannot exceed limits (service stops)

### Pro Plan ($25+/month)

**Base**: $25/month

**Realtime**:
- 5M messages/month included
- Then $2.50 per million messages
- 500 peak concurrent connections
- Additional connections: $10 per 1,000

**Database**:
- 8GB database space included
- Then $0.125/GB
- Daily backups (7-day retention)
- No automatic pause

**Storage**:
- 100GB storage included
- Then $0.021/GB

**Bandwidth**:
- 250GB included
- Then $0.09/GB

**Authentication**:
- 100,000 MAUs included
- Then $0.00325 per MAU

**Edge Functions**:
- 2M invocations included
- Then $2 per million

**Compute**:
- Micro instance included ($10 value)
- Can upgrade to larger instances

**Support**:
- Email support
- 2-day response time

### Team Plan ($599+/month)

**Base**: $599/month

**Everything in Pro, plus**:
- Daily backups (14-day retention)
- Priority email support
- SOC2 compliance
- SSO (SAML 2.0)
- Advanced audit logs
- Custom contracts available

### Enterprise Plan (Custom)

**Base**: Custom pricing

**Everything in Team, plus**:
- Custom contracts
- Dedicated support
- SLA guarantees
- Priority feature requests
- Annual billing options
- Volume discounts

---

## Additional Costs (Pro Plan)

Beyond the $25 base fee, you pay for:

| Resource | Included | Additional Cost |
|----------|----------|-----------------|
| **Realtime messages** | 5M/month | $2.50/million |
| **Realtime connections** | 500 peak | $10/1,000 |
| **Database** | 8GB | $0.125/GB |
| **Storage** | 100GB | $0.021/GB |
| **Bandwidth** | 250GB | $0.09/GB |
| **MAUs** | 100K | $0.00325/MAU |
| **Function invocations** | 2M | $2/million |
| **Compute** | Micro instance | Varies by size |

---

## Example Costs

### Small App (10K Users, 5M Messages/Month)

Assumptions:
- 10,000 MAUs
- 5M realtime messages/month
- 500 concurrent connections (peak)
- 5GB database
- 50GB storage
- 100GB bandwidth

**Cost breakdown**:
- Base: $25
- Realtime: 5M included
- Connections: 500 included
- Database: 8GB included
- Storage: 100GB included
- Bandwidth: 250GB included
- MAUs: 100K included
- **Total**: **$25/month**

### Medium App (50K Users, 50M Messages/Month)

Assumptions:
- 50,000 MAUs
- 50M realtime messages/month
- 2,500 concurrent connections
- 20GB database
- 200GB storage
- 500GB bandwidth

**Cost breakdown**:
- Base: $25
- Realtime: 5M inc + (45M × $2.50/M) = $112.50
- Connections: 500 inc + (2,000 × $10/1K) = $20
- Database: 8GB inc + (12GB × $0.125) = $1.50
- Storage: 100GB inc + (100GB × $0.021) = $2.10
- Bandwidth: 250GB inc + (250GB × $0.09) = $22.50
- MAUs: 100K included
- **Total**: **~$183.60/month**

### Large App (200K Users, 500M Messages/Month)

Assumptions:
- 200,000 MAUs
- 500M realtime messages/month
- 10,000 concurrent connections
- 50GB database
- 500GB storage
- 2TB bandwidth

**Cost breakdown**:
- Base: $25
- Realtime: 5M inc + (495M × $2.50/M) = $1,237.50
- Connections: 500 inc + (9,500 × $10/1K) = $95
- Database: 8GB inc + (42GB × $0.125) = $5.25
- Storage: 100GB inc + (400GB × $0.021) = $8.40
- Bandwidth: 250GB inc + (1,750GB × $0.09) = $157.50
- MAUs: 100K inc + (100K × $0.00325) = $325
- **Total**: **~$1,853.65/month**

---

## Key Features

### Realtime Database
- PostgreSQL with realtime subscriptions
- Row-level security
- Built on PostgreSQL replication
- WebSocket connections
- Broadcast and presence features

### Database
- PostgreSQL database
- Connection pooling
- Automatic backups
- Point-in-time recovery (Pro+)

### Authentication
- Email/password
- Magic links
- Social OAuth (Google, GitHub, etc.)
- Phone auth
- SAML SSO (Team plan)

### Storage
- S3-compatible object storage
- File uploads
- Image transformations
- CDN-backed

### Edge Functions
- Deno-based serverless functions
- TypeScript support
- Global deployment

---

## Advantages

1. ✅ **Full backend platform**: Database, auth, storage, functions all included
2. ✅ **PostgreSQL-based**: Powerful relational database
3. ✅ **Open source**: Can self-host
4. ✅ **Generous free tier**: Good for small projects
5. ✅ **Affordable entry**: $25/month base
6. ✅ **Strong developer tools**: Dashboard, CLI, migrations

---

## Disadvantages

1. ❌ **Cannot use standalone**: Must pay for entire platform
2. ❌ **Message costs add up**: $2.50/million after 5M
3. ❌ **Connection fees**: $10 per 1,000 additional connections
4. ❌ **Compute costs**: Projects need paid compute ($10+/month)
5. ❌ **Bandwidth charges**: $0.09/GB after 250GB
6. ❌ **Multiple cost factors**: Messages, connections, bandwidth, storage all charged separately

---

## Comparison to Firebase + FirebaseRealtimeToolkit

| Metric | Supabase | Firebase Toolkit |
|--------|----------|------------------|
| **Pricing Model** | Platform + per-resource | Bandwidth only |
| **Minimum cost** | $25/month | $0 |
| **Small (10K users)** | $25/month | ~$5/month |
| **Medium (50K users)** | $184/month | ~$40/month |
| **Large (200K users)** | $1,854/month | ~$490/month |
| **Free Tier** | 2M messages, 200 connections | 10GB bandwidth |
| **Standalone realtime** | No (full platform required) | Yes |
| **Database** | PostgreSQL included | Use RTDB or Firestore |

**Savings with Firebase Toolkit**: 60-75% for realtime-only use cases

---

## When to Choose Supabase

- ✅ You want a **full backend platform** (database, auth, storage, functions)
- ✅ You prefer **PostgreSQL** over NoSQL
- ✅ You need **row-level security**
- ✅ You want **open source** with self-hosting option
- ✅ You like **SQL queries** and relational data
- ✅ You need **all features** Supabase offers, not just realtime

## When to Choose Firebase Toolkit

- ✅ You only need **realtime data streaming**
- ✅ You want **the most cost-effective** realtime solution
- ✅ You prefer **NoSQL** (Firebase RTDB/Firestore)
- ✅ You don't want to pay for unused platform features
- ✅ You want **simpler pricing** (bandwidth only)
- ✅ You have **budget constraints**

## When They're Not Directly Comparable

**Supabase** is a full platform like Firebase, not just a realtime service. The comparison depends on what you need:

1. **Need full backend platform?**
   - **Supabase**: $25+/month for everything
   - **Firebase**: Free to start, pay for what you use

2. **Only need realtime?**
   - **Firebase Toolkit**: Much cheaper
   - **Supabase**: Paying for features you don't use

3. **Need PostgreSQL?**
   - **Supabase**: Best choice
   - **Firebase**: Use Firestore (NoSQL) instead

---

## Notable Differences

### Supabase Realtime vs Firebase RTDB

| Feature | Supabase | Firebase RTDB |
|---------|----------|---------------|
| **Database** | PostgreSQL | JSON tree |
| **Query language** | SQL | Firebase queries |
| **Realtime method** | PostgreSQL replication | WebSocket streaming |
| **Offline support** | Limited | Strong (Firebase SDK) |
| **Scaling** | Vertical (bigger instances) | Horizontal (sharding) |

### When to Use Each

**Use Supabase** if:
- Need relational data with SQL
- Want full platform in one place
- Prefer PostgreSQL
- Need complex joins and queries

**Use Firebase + Toolkit** if:
- Need cost-effective realtime
- Want lightweight streaming
- Prefer NoSQL
- Need offline-first with sync

---

## Cost Optimization Tips

1. **Monitor realtime messages**: They add up at $2.50/M
2. **Use database efficiently**: Storage costs $0.125/GB
3. **Optimize bandwidth**: $0.09/GB after 250GB
4. **Connection pooling**: Avoid hitting connection limits
5. **Use free tier**: Great for prototypes
6. **Consider self-hosting**: Open source option for large scale

---

## Last Updated

February 3, 2026
