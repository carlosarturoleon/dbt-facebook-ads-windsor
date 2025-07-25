# dbt Facebook Ads Windsor Package

A production-ready dbt package that transforms raw Facebook Ads data from Windsor.ai into clean, analytics-ready tables in BigQuery following standardized architecture patterns.

## 🚀 Features
- **Multi-Source Integration**: Support for campaigns, ads, and insights data tables
- **Data Quality**: Comprehensive testing suite with deduplication and validation
- **Type Safety**: Robust string-to-numeric conversions with safe_cast
- **Business Metrics**: Pre-calculated CTR, CPC, ROAS, and conversion rates
- **Performance Optimized**: BigQuery-optimized data types and filtering
- **Windsor.ai Integration**: Purpose-built for Windsor.ai Facebook Ads data structure

## 📊 Staging Models

| Model | Source Table | Grain | Description |
|-------|--------------|-------|-------------|
| `stg_facebook_ads__campaigns` | `facebook_ads_windsor_campaigns` | Campaign | Campaign-level entities with hierarchy and metadata |
| `stg_facebook_ads__ads` | `facebook_ads_windsor_ads` | Ad | Ad-level entities with creative information |
| `stg_facebook_ads__insights` | `facebook_ads_windsor_insights` | Date + Account + Campaign + Ad | Daily performance metrics with deduplication |

## 🏗️ Project Structure

```
models/
├── staging/
│   └── facebook_ads/
│       ├── stg_facebook_ads__campaigns.sql  # Campaign entities
│       ├── stg_facebook_ads__ads.sql        # Ad creative entities  
│       ├── stg_facebook_ads__insights.sql   # Performance insights
│       ├── sources.yml                      # Source table definitions
│       └── schema.yml                       # Model documentation & tests
analysis/
└── windsor_data_profiling.sql              # Data profiling queries
```

## 🛠 Quick Start

1. **Configure your `dbt_project.yml`**:
```yaml
vars:
  facebook_ads_source_table: 'your-project.raw_data.facebook_ads_windsor_campaigns'
  facebook_ads_start_date: '2024-01-01'
  exclude_test_campaigns: true
  min_spend_threshold: 0
  min_impressions_threshold: 1
```

2. **Source Tables Required**:
- `facebook_ads_windsor_campaigns`: Campaign-level data
- `facebook_ads_windsor_ads`: Ad creative data  
- `facebook_ads_windsor_insights`: Performance metrics data

3. **Run the models**:
```bash
dbt run --select +stg_facebook_ads
dbt test --select +stg_facebook_ads
```

## 📋 Data Sources

### Source: `facebook_ads_windsor_campaigns`
Contains campaign-level information including objectives, budgets, and status.

**Key Fields**: `account_id`, `campaign_id`, `campaign_name`, `campaign_objective`, `campaign_status`, `campaign_budget_*`

### Source: `facebook_ads_windsor_ads` 
Contains ad-level creative information and metadata.

**Key Fields**: `actor_id`, `ad_id`, `ad_name`, `adset_id`, `title`, `body`, `link_url`, `thumbnail_url`

### Source: `facebook_ads_windsor_insights`
Contains daily performance metrics at the ad level.

**Key Fields**: `date`, `account_id`, `campaign_id`, `ad_id`, `impressions`, `clicks`, `spend`, `actions_purchase`

## ⚙️ Configuration

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `facebook_ads_start_date` | `2024-01-01` | Start date for data processing |
| `exclude_test_campaigns` | `true` | Filter out test campaigns/ads |
| `min_spend_threshold` | `0` | Minimum spend to include records |
| `min_impressions_threshold` | `1` | Minimum impressions to include records |

### Data Quality Features

- **Deduplication**: Automatic removal of duplicate records by grain
- **Type Conversion**: Safe string-to-numeric casting for purchase fields
- **Null Handling**: Proper coalesce logic for missing data
- **Test Coverage**: Comprehensive dbt tests for data validation

## 🧪 Testing

The package includes extensive data quality tests:

- **Uniqueness**: Ensures grain uniqueness across models
- **Not Null**: Validates required fields
- **Referentials**: Checks hierarchical relationships
- **Business Logic**: Validates calculated metrics (ROAS, CPC, etc.)
- **Data Quality**: Flags invalid or suspicious data

Run tests:
```bash
dbt test --select stg_facebook_ads
```

## 📈 Calculated Metrics

### Performance Metrics
- **Click-Through Rate**: `clicks / impressions * 100`
- **Cost Per Click**: `spend / clicks`
- **Cost Per Mille**: `spend / impressions * 1000`

### Conversion Metrics  
- **Cost Per Conversion**: `spend / conversions`
- **Return on Ad Spend**: `conversion_value / spend`
- **Conversion Rate**: `conversions / clicks * 100`

## 🔧 Troubleshooting

### Common Issues

**String Conversion Errors**: The package uses `safe_cast()` to handle string-to-numeric conversions for fields like `actions_purchase`, `action_values_purchase`, and `ctr`.

**Duplicate Records**: The insights model includes automatic deduplication logic that keeps the record with highest spend/impressions for each grain.

**Test Failures**: Check the `return_on_ad_spend_consistency` test - it handles cases where conversion data may not be available.

## 📚 Additional Resources

- **Data Profiling**: Use `analysis/windsor_data_profiling.sql` to understand your data
- **Source Documentation**: See `models/staging/facebook_ads/sources.yml` for field definitions
- **Model Tests**: Review `models/staging/facebook_ads/schema.yml` for validation logic

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.