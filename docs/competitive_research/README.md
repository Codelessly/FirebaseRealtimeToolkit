# Competitive Research - Detailed Pricing Analysis

This folder contains in-depth pricing analyses for all major competitors in the realtime platform space.

## 📂 Structure

### Main Document
- **[../PRICING_COMPARISON.md](../PRICING_COMPARISON.md)** - Start here! Comprehensive overview with cost comparisons and recommendations.

### Detailed Competitor Analyses

#### Core Realtime Competitors
1. **[pusher.md](./pusher.md)** - Pusher Channels (message + connection based)
2. **[pubnub.md](./pubnub.md)** - PubNub (MAU-based pricing)
3. **[ably.md](./ably.md)** - Ably Realtime (per-minute pricing)

#### Full Platform Competitors
4. **[supabase.md](./supabase.md)** - Supabase (PostgreSQL platform)
5. **[appwrite.md](./appwrite.md)** - Appwrite (open-source BaaS)

#### Our Platform
6. **[firebase.md](./firebase.md)** - Firebase (what we use)

### Legacy Documents
- **[OLD_PRICING_COMPARISON.md](./OLD_PRICING_COMPARISON.md)** - Original comprehensive analysis
- **[OLD_PRICING_EXECUTIVE_SUMMARY.md](./OLD_PRICING_EXECUTIVE_SUMMARY.md)** - Original executive summary

---

## 📊 Quick Cost Comparison

| Provider | Small (10K users) | Medium (50K users) | Large (200K users) |
|----------|-------------------|--------------------|--------------------|
| **Firebase Toolkit** | **$5/mo** | **$40/mo** | **$490/mo** |
| Pusher | $49-99/mo | $99-299/mo | $699-899/mo |
| PubNub | $500/mo | $1,900/mo | $3,000+/mo |
| Ably | $39/mo | $509/mo | $1,634/mo |
| Supabase | $25/mo | $184/mo | $1,854/mo |
| Appwrite | $25/mo | $43/mo | $238/mo |

---

## 🎯 Use Cases

### Choose Firebase Toolkit When:
- ✅ You want the most cost-effective solution (70-95% savings)
- ✅ You need unlimited messages without per-message fees
- ✅ You want a lightweight SDK (500KB)
- ✅ You're building Flutter/Dart apps
- ✅ You have budget constraints

### Explore Competitors When:
- You need zero-setup managed service (Pusher)
- You want 99.999% SLA out of the box (PubNub)
- You need guaranteed message delivery (Ably)
- You prefer PostgreSQL (Supabase)
- You want unlimited messages bundled (Appwrite)

---

## 📖 How to Read These Documents

Each competitor document includes:

1. **Overview** - What they offer and their pricing page
2. **Pricing Model** - How they charge (per message, MAU, etc.)
3. **Pricing Tiers** - Detailed plan breakdown
4. **Example Costs** - Real-world scenarios at different scales
5. **Advantages** - What they do well
6. **Disadvantages** - Where they fall short
7. **Comparison to Firebase Toolkit** - Direct cost comparison
8. **When to Choose** - Recommendations for each use case

---

## 🔍 Research Methodology

Our pricing analysis is based on:

1. **Official pricing pages** (as of February 2026)
2. **Real-world usage scenarios** (10K, 50K, 200K, 1M users)
3. **Message volume estimates** (5M to 5B messages/month)
4. **Bandwidth calculations** (based on typical message sizes)
5. **Public documentation** and pricing calculators

All pricing is verified from official sources and updated regularly.

---

## 💡 Key Insights

### Why Firebase Toolkit is Cheaper

1. **No per-message fees**: Competitors charge $0.50-$2.50 per million messages
2. **No connection fees**: Firebase allows 200K concurrent connections free
3. **No platform fees**: Supabase/Appwrite charge $25+ base for full platform
4. **Bandwidth-based**: You pay for actual data transfer, not message counts

### When Competitors Might Win

- **Very low bandwidth, high message count**: Millions of tiny messages
- **Need enterprise features out of the box**: HIPAA, SOC 2, SLAs
- **Want zero setup**: Fully managed with no Firebase knowledge needed
- **Need full platform**: Database, auth, storage all in one

---

## 🔄 Updates

This documentation is updated regularly to reflect:
- Pricing changes from competitors
- New competitors entering the market
- Feature additions and improvements
- Community feedback and real-world data

**Last Updated**: February 3, 2026

---

## 📞 Contribute

Found an error or have updated pricing information?

1. Open an issue on [GitHub](https://github.com/Codelessly/firebase_realtime_toolkit/issues)
2. Submit a pull request
3. Contact us with the latest information

---

## 🚀 Get Started

Ready to save 70-95% on your realtime infrastructure?

```bash
dart pub add firebase_realtime_toolkit
```

See the [main pricing comparison](../PRICING_COMPARISON.md) for detailed cost analysis and recommendations.

---

Made with ❤️ by the Codelessly team
