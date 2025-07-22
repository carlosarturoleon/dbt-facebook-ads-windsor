{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_data', 'facebook_ads_windsor') }}
),

cleaned_data as (
  select
    date as date_day,
    account_id,
    account_name,
    campaign_id,
    campaign as campaign_name,
    case 
      when upper(campaign_objective) = 'APP_INSTALLS' then 'App Installs'
      when upper(campaign_objective) = 'BRAND_AWARENESS' then 'Brand Awareness'
      when upper(campaign_objective) = 'CONVERSIONS' then 'Conversions'
      when upper(campaign_objective) = 'EVENT_RESPONSES' then 'Event Responses'
      when upper(campaign_objective) = 'LEAD_GENERATION' then 'Lead Generation'
      when upper(campaign_objective) = 'LINK_CLICKS' then 'Link Clicks'
      when upper(campaign_objective) = 'LOCAL_AWARENESS' then 'Local Awareness'
      when upper(campaign_objective) = 'MESSAGES' then 'Messages'
      when upper(campaign_objective) = 'OFFER_CLAIMS' then 'Offer Claims'
      when upper(campaign_objective) = 'OUTCOME_APP_PROMOTION' then 'Outcome App Promotion'
      when upper(campaign_objective) = 'OUTCOME_AWARENESS' then 'Outcome Awareness'
      when upper(campaign_objective) = 'OUTCOME_ENGAGEMENT' then 'Outcome Engagement'
      when upper(campaign_objective) = 'OUTCOME_LEADS' then 'Outcome Leads'
      when upper(campaign_objective) = 'OUTCOME_SALES' then 'Outcome Sales'
      when upper(campaign_objective) = 'OUTCOME_TRAFFIC' then 'Outcome Traffic'
      when upper(campaign_objective) = 'PAGE_LIKES' then 'Page Likes'
      when upper(campaign_objective) = 'POST_ENGAGEMENT' then 'Post Engagement'
      when upper(campaign_objective) = 'PRODUCT_CATALOG_SALES' then 'Product Catalog Sales'
      when upper(campaign_objective) = 'REACH' then 'Reach'
      when upper(campaign_objective) = 'STORE_VISITS' then 'Store Visits'
      when upper(campaign_objective) = 'VIDEO_VIEWS' then 'Video Views'
      else campaign_objective
    end as campaign_objective,
    campaign_status,
    ad_id,
    ad_name,
    impressions,
    clicks,
    spend,
    reach,
    frequency,
    cpm as cost_per_mille,
    cpc as cost_per_click,
    ctr as click_through_rate,
    actions_purchase as conversions,
    action_values_purchase as conversion_value,
    safe_divide(spend, nullif(actions_purchase, 0)) as cost_per_conversion,
    safe_divide(action_values_purchase, nullif(spend, 0)) as return_on_ad_spend
  from source_data
)

select * from cleaned_data
where 1=1
  and date_day is not null
  and account_id is not null
  and campaign_id is not null
  and date_day >= '{{ var("facebook_ads_start_date") }}'
  {% if var("exclude_test_campaigns", true) %}
  and not (
    lower(campaign_name) like '%test%' 
    or lower(ad_name) like '%test%'
  )
  {% endif %}
  and spend >= {{ var("min_spend_threshold", 0) }}
  and spend >= 0
  and clicks >= 0
  and impressions >= 0
  and (clicks <= impressions or impressions is null)