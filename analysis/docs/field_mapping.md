# Facebook Ads Field Mapping Documentation

## Source Data Structure (Windsor.ai)

Windsor.ai Facebook Ads data structure:

### Raw Table Schema
| Windsor.ai Field | Data Type | Sample Values | Notes |
|-----------------|-----------|---------------|-------|
| date | DATE | 2024-01-15 | Report date |
| account_id | STRING | 123456789 | Facebook Ad Account ID |
| account_name | STRING | "Company Ads Account" | Business Manager account name |
| campaign_id | STRING | 987654321 | Facebook Campaign ID |
| campaign_name | STRING | "Q1 Lead Generation" | Campaign name |
| campaign_objective | STRING | "LEAD_GENERATION" | Facebook campaign objective |
| campaign_status | STRING | "ACTIVE" | Campaign status |
| ad_id | STRING | 456789123 | Facebook Ad ID |
| ad_name | STRING | "Video Creative A" | Ad name |
| impressions | INTEGER | 10500 | Number of impressions |
| clicks | INTEGER | 250 | Number of clicks |
| spend | FLOAT | 125.50 | Amount spent in account currency |
| reach | INTEGER | 8500 | Unique users reached |
| frequency | FLOAT | 1.24 | Average impressions per user |
| cpm | FLOAT | 11.95 | Cost per 1000 impressions |
| cpc | FLOAT | 0.50 | Cost per click |
| ctr | FLOAT | 2.38 | Click-through rate (%) |
| conversions | INTEGER | 15 | Total conversions |
| conversion_value | FLOAT | 750.00 | Total conversion value |

## Target Schema Mapping

### Account Report (`facebook_ads__account_report`)

| Target Field | Data Type | Source Field(s) | Transformation | Business Logic |
|--------------|-----------|-----------------|----------------|----------------|
| **Identifiers** |||||
| date_day | DATE | date | Direct mapping | Report date |
| account_id | STRING | account_id | Direct mapping | Facebook Ad Account ID |
| account_name | STRING | account_name | Direct mapping | Account display name |
| **Core Metrics** |||||
| impressions | INTEGER | impressions | SUM() | Total daily impressions |
| clicks | INTEGER | clicks | SUM() | Total daily clicks |
| spend | FLOAT64 | spend | SUM() | Total daily spend |
| reach | INTEGER | reach | SUM() | Total unique reach |
| **Calculated Metrics** |||||
| cost_per_click | FLOAT64 | - | spend / NULLIF(clicks, 0) | Average CPC |
| click_through_rate | FLOAT64 | - | clicks / NULLIF(impressions, 0) * 100 | CTR percentage |
| cost_per_mille | FLOAT64 | - | spend / NULLIF(impressions, 0) * 1000 | CPM |
| frequency | FLOAT64 | - | impressions / NULLIF(reach, 0) | Avg frequency |
| **Conversion Metrics** |||||
| conversions | INTEGER | conversions | SUM() | Total conversions |
| conversion_value | FLOAT64 | conversion_value | SUM() | Total conversion value |
| cost_per_conversion | FLOAT64 | - | spend / NULLIF(conversions, 0) | Average cost per conversion |
| return_on_ad_spend | FLOAT64 | - | conversion_value / NULLIF(spend, 0) | ROAS ratio |

### Campaign Report (`facebook_ads__campaign_report`)

| Target Field | Data Type | Source Field(s) | Transformation | Business Logic |
|--------------|-----------|-----------------|----------------|----------------|
| **Identifiers** |||||
| date_day | DATE | date | Direct mapping | Report date |
| account_id | STRING | account_id | Direct mapping | Parent account |
| account_name | STRING | account_name | Direct mapping | Account display name |
| campaign_id | STRING | campaign_id | Direct mapping | Facebook Campaign ID |
| campaign_name | STRING | campaign_name | Direct mapping | Campaign display name |
| **Campaign Properties** |||||
| campaign_objective | STRING | campaign_objective | Standardized mapping | Mapped to standard values |
| campaign_status | STRING | campaign_status | Standardized mapping | ACTIVE/PAUSED/ARCHIVED |
| **Metrics** |||||
| [All metrics from Account Report] | | | | Aggregated at campaign level |

### Ad Report (`facebook_ads__ad_report`)

| Target Field | Data Type | Source Field(s) | Transformation | Business Logic |
|--------------|-----------|-----------------|----------------|----------------|
| **Identifiers** |||||
| date_day | DATE | date | Direct mapping | Report date |
| account_id | STRING | account_id | Direct mapping | Parent account |
| campaign_id | STRING | campaign_id | Direct mapping | Parent campaign |
| campaign_name | STRING | campaign_name | Direct mapping | Campaign display name |
| ad_id | STRING | ad_id | Direct mapping | Facebook Ad ID |
| ad_name | STRING | ad_name | Direct mapping | Ad display name |
| **Ad Properties** |||||
| campaign_objective | STRING | campaign_objective | Direct mapping | Inherited from campaign |
| **Metrics** |||||
| [All metrics from Account Report] | | | | At ad granularity (no aggregation) |

## Data Transformation Rules

### Campaign Objective Standardization
```sql
CASE 
  WHEN UPPER(campaign_objective) = 'LEAD_GENERATION' THEN 'Lead Generation'
  WHEN UPPER(campaign_objective) = 'CONVERSIONS' THEN 'Conversions'
  WHEN UPPER(campaign_objective) = 'TRAFFIC' THEN 'Traffic'
  WHEN UPPER(campaign_objective) = 'BRAND_AWARENESS' THEN 'Brand Awareness'
  WHEN UPPER(campaign_objective) = 'REACH' THEN 'Reach'
  WHEN UPPER(campaign_objective) = 'VIDEO_VIEWS' THEN 'Video Views'
  WHEN UPPER(campaign_objective) = 'MESSAGES' THEN 'Messages'
  ELSE campaign_objective
END as campaign_objective