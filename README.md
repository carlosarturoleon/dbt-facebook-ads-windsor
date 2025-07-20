# dbt Facebook Ads Data Package

A production ready dbt package that transforms raw Facebook Ads data from Windsor.ai into clean, analytics-ready tables in BigQuery following standardized architecture patterns.

## 🚀 Features
- **Standardized Models**: Account, campaign, and ad level reporting with hierarchical naming
- **Business Metrics**: Pre-calculated CTR, CPC, ROAS, and conversion rates
- **Data Quality**: Testing suite with business logic validation
- **Performance Optimized**: BigQuery partitioning and clustering for cost efficiency
- **Windsor.ai Integration**: Purpose-built for Windsor.ai Facebook Ads data structure

## 📊 Models Overview

| Model | Grain | Description |
|-------|-------|-------------|
| `facebook_ads__account_report` | Account + Date | Daily account-level performance metrics |
| `facebook_ads__campaign_report` | Campaign + Date | Campaign performance with objectives |
| `facebook_ads__ad_report` | Ad + Date | Individual ad creative performance |

## 🛠 Quick Start

1. Add to your `packages.yml`:
```yaml
packages:
  - git: "https://github.com/windsor-ai/dbt_facebook_ads_windsor.git"
    revision: v1.0.0