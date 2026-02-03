# Appwrite - Detailed Pricing Analysis

## Overview

Appwrite is an open-source backend-as-a-service platform that provides database, authentication, storage, functions, and realtime features in one package.

**Website**: https://appwrite.io/
**Pricing Page**: https://appwrite.io/pricing

---

## Pricing Model

Appwrite uses a **bundled platform pricing model** with a base fee plus usage-based costs for various resources. Realtime is included but you cannot use it standalone.

---

## Pricing Tiers

| Plan | Base Price/Month | Messages | Concurrent Connections | Additional Connections |
|------|------------------|----------|------------------------|------------------------|
| **Free** | **$0** | 3M/month | 250 | N/A |
| **Pro** | **$25+** | Unlimited | 500 | $5 per 1,000 |
| **Enterprise** | **Custom** | Unlimited | Custom | Custom |

---

## Plan Details

### Free Plan ($0/month)

**Realtime**:
- 3M messages/month
- 250 concurrent connections
- Unlimited messages included

**Projects**:
- 2 projects (shared resources)
- 3 connected websites/apps per project

**Bandwidth**:
- 5GB/month

**Storage**:
- 2GB total

**Database**:
- 1 database per project
- 500K reads/month
- 250K writes/month

**Functions**:
- 2 functions per project
- 750K executions/month
- 100 GB-hours/month

**Authentication**:
- 75K Monthly Active Users

**Support**:
- Community support only

**Retention**:
- 1 hour log retention

### Pro Plan ($25+/month)

**Base**: $25/month per project

**Realtime**:
- **Unlimited messages** ✅
- 500 concurrent connections included
- Additional connections: $5 per 1,000

**Projects**:
- 1 project (dedicated resources)
- Additional projects: $15/month each
- Unlimited websites/apps per project

**Bandwidth**:
- 2TB included
- Then $15 per 100GB

**Storage**:
- 150GB included
- Then $2.80 per 100GB

**Database**:
- Unlimited databases
- 1.75M reads/month included
- 750K writes/month included
- Additional reads: $0.060 per 100K
- Additional writes: $0.10 per 100K
- Daily backups (7-day retention)

**Functions**:
- Unlimited functions
- 3.5M executions/month included
- 1,000 GB-hours/month included
- Additional executions: $2 per million
- Additional GB-hours: $0.06 per GB-hour
- Up to 4 CPUs, 4GB RAM per function

**Authentication**:
- 200K MAUs included
- Then $3 per 1,000 users

**Storage Features**:
- 100 origin image transformations/month
- Then $5 per 1,000 origin images
- 5GB max file upload size

**Support**:
- Email support
- Budget caps and alerts

**Retention**:
- 7 days log retention

**Other Features**:
- No Appwrite branding on emails
- Custom SMTP
- Unlimited webhooks

### Enterprise Plan (Custom)

**Base**: Custom pricing

**Everything in Pro, plus**:
- Custom SLAs
- Designated Success Manager
- 24/7 support option
- Private Slack channel option
- Volume discounts
- Log drains
- 90-day log retention
- Advanced observability
- Bring your own Cloud
- SOC-2, HIPAA, BAA compliance
- SSO (Single Sign-On)
- Activity logs
- Custom backup policies
- Custom organization roles

---

## Example Costs

### Small App (10K Users, 5M Messages/Month)

Assumptions:
- 10,000 MAUs
- 5M messages/month (unlimited)
- 500 concurrent connections (included)
- 5GB bandwidth
- 10GB storage
- 1M database reads, 500K writes
- 1M function executions

**Cost breakdown**:
- Base: $25
- Realtime: Unlimited messages ✅
- Connections: 500 included ✅
- Bandwidth: 2TB included ✅
- Storage: 150GB included ✅
- Database: Included in free tier ✅
- Functions: Included ✅
- MAUs: 200K included ✅
- **Total**: **$25/month** 🎉

### Medium App (50K Users, 50M Messages/Month)

Assumptions:
- 50,000 MAUs
- 50M messages/month (unlimited)
- 2,500 concurrent connections
- 50GB bandwidth
- 200GB storage
- 5M database reads, 2M writes
- 5M function executions

**Cost breakdown**:
- Base: $25
- Realtime: Unlimited messages ✅
- Connections: 500 inc + (2,000 × $5/1K) = $10
- Bandwidth: 2TB included ✅
- Storage: 150GB inc + (50GB × $2.80/100GB) = $1.40
- Database: 1.75M inc + (3.25M reads × $0.06/100K) = $1.95
  - Writes: 750K inc + (1.25M × $0.10/100K) = $1.25
- Functions: 3.5M inc + (1.5M × $2/M) = $3
- MAUs: 200K included ✅
- **Total**: **~$42.60/month**

### Large App (200K Users, 500M Messages/Month)

Assumptions:
- 200,000 MAUs
- 500M messages/month (unlimited)
- 10,000 concurrent connections
- 500GB bandwidth
- 1TB storage
- 50M database reads, 20M writes
- 50M function executions

**Cost breakdown**:
- Base: $25
- Realtime: Unlimited messages ✅
- Connections: 500 inc + (9,500 × $5/1K) = $47.50
- Bandwidth: 2TB included ✅
- Storage: 150GB inc + (850GB × $2.80/100GB) = $23.80
- Database reads: 1.75M inc + (48.25M × $0.06/100K) = $28.95
  - Writes: 750K inc + (19.25M × $0.10/100K) = $19.25
- Functions: 3.5M inc + (46.5M × $2/M) = $93
- MAUs: 200K inc + (0 × $3/1K) = $0
- **Total**: **~$237.50/month**

---

## Key Features

### Realtime
- Unlimited messages on Pro+
- Concurrent connection limits
- WebSocket-based
- Works across all Appwrite services

### Databases
- Multiple databases per project (Pro)
- NoSQL document database
- Unlimited documents
- Relationship support
- Full-text search
- Encrypted attributes (Pro)

### Authentication
- Email/password
- OAuth providers
- Magic URL
- Phone authentication
- Anonymous login
- JWT tokens
- Teams & permissions

### Storage
- File uploads
- Image transformations
- CDN delivery
- Virus scanning
- Encryption at rest

### Functions
- Node.js, Python, PHP, Ruby, Dart, etc.
- 0.5 to 4 CPUs (Pro)
- 512MB to 4GB RAM (Pro)
- Express builds (Pro)
- Automatic deployments

---

## Advantages

1. ✅ **Unlimited realtime messages**: No message limits on Pro plan
2. ✅ **Open source**: Can self-host
3. ✅ **Affordable base**: $25/month starting
4. ✅ **Full platform**: Database, auth, storage, functions included
5. ✅ **Generous limits**: 2TB bandwidth, 150GB storage on Pro
6. ✅ **No branding**: Remove Appwrite branding from emails
7. ✅ **Daily backups**: Automatic backups on Pro

---

## Disadvantages

1. ❌ **Per-project pricing**: $15 for each additional project adds up
2. ❌ **Connection fees**: $5 per 1,000 additional connections
3. ❌ **Cannot use standalone**: Must pay for entire platform
4. ❌ **Limited free tier**: Only 250 connections, 5GB bandwidth
5. ❌ **Database read/write costs**: Can add up with high traffic
6. ❌ **Function execution costs**: $2 per million

---

## Comparison to Firebase + FirebaseRealtimeToolkit

| Metric | Appwrite | Firebase Toolkit |
|--------|----------|------------------|
| **Pricing Model** | Platform + resources | Bandwidth only |
| **Base cost** | $25/month | $0 |
| **Messages** | Unlimited ✅ | Unlimited ✅ |
| **Small (10K users)** | $25/month | ~$5/month |
| **Medium (50K users)** | $43/month | ~$40/month |
| **Large (200K users)** | $238/month | ~$490/month |
| **Free Tier** | 3M messages, 250 connections | 10GB bandwidth |
| **Standalone** | No | Yes |
| **Per-project fee** | $15/project | $0 |

**Savings with Firebase Toolkit**:
- **Small scale**: 80% savings
- **Medium scale**: Comparable
- **Large scale**: Appwrite can be cheaper!

---

## When to Choose Appwrite

- ✅ You want **unlimited realtime messages** included
- ✅ You need a **full backend platform** (not just realtime)
- ✅ You prefer **open source** with self-hosting option
- ✅ You like **predictable costs** (unlimited messages)
- ✅ You need all features: database, auth, storage, functions
- ✅ You have **medium to large scale** (200K+ users)
- ✅ Your message volume is extremely high

## When to Choose Firebase Toolkit

- ✅ You only need **realtime data streaming**
- ✅ You want **no platform fees** ($0 base)
- ✅ You have **small scale** (< 50K users)
- ✅ You have **multiple projects** (avoid $15/project fees)
- ✅ You prefer **Firebase ecosystem**
- ✅ You want **simpler pricing** (bandwidth only)

## When They're Comparable

At **50K-200K user scale**, Appwrite and Firebase Toolkit are cost-competitive. Choose based on:
- **Appwrite**: If you need the full platform
- **Firebase**: If you only need realtime + lightweight SDK

---

## Notable Features

### Unlimited Realtime Messages
Unlike most competitors, Appwrite Pro includes **unlimited realtime messages**. This is huge for high-volume apps.

### Per-Project Pricing
- Each project: $25/month base
- Additional projects: $15/month each
- Multi-tenant apps may need multiple projects

### Open Source
- Can self-host for free
- Full source code available
- Community-driven development

### Express Builds (Pro)
- Faster function deployments
- CI/CD optimizations

---

## Cost Optimization Tips

1. **Consolidate projects**: Avoid $15/month per extra project
2. **Monitor connections**: Additional connections cost $5/1K
3. **Optimize database queries**: Reads/writes have costs
4. **Use bandwidth wisely**: 2TB included, but overages cost $15/100GB
5. **Leverage unlimited messages**: Take advantage of this on Pro
6. **Consider self-hosting**: For very large scale

---

## Data Retention Notes

**Free Plan**:
- Retains subscription records active in past 18 months
- Dormant records deleted after 18 months

**Pro Plan**:
- Retains all subscription data until you delete it
- No automatic deletion

---

## Last Updated

February 3, 2026
