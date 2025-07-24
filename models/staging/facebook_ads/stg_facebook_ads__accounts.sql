{{ config(materialized='view') }}

with source_data as (
  select * from {{ source('raw_data', 'facebook_ads_windsor_real') }}
),

unique_accounts as (
  select distinct
    account_id,
    account_name,
    account_status,
    account_currency,
    currency,
    -- Aggregate campaign statuses to understand account activity
    string_agg(distinct campaign_status, ', ' order by campaign_status) as campaign_statuses,
    count(distinct campaign_status) as distinct_campaign_statuses_count,
    -- Check if account has any active campaigns based on campaign_status
    countif(upper(campaign_status) in ('ACTIVE', 'LEARNING', 'LEARNING LIMITED')) > 0 as has_active_campaigns
  from source_data
  where account_id is not null
    and account_id != ''
  group by account_id, account_name, account_status, account_currency, currency
),

cleaned_accounts as (
  select
    {{ dbt_utils.generate_surrogate_key(['account_id']) }} as account_key,
    
    cast(account_id as string) as account_id,
    
    case 
      when trim(account_name) = '' or account_name is null then 'Unknown Account'
      when regexp_contains(trim(account_name), r'^[0-9]+$') then concat('Account ', trim(account_name))
      else trim(regexp_replace(account_name, r'\s+', ' '))
    end as account_name_clean,
    
    cast(account_name as string) as account_name_raw,
    
    -- Account status from source data (standardized)
    case 
      when upper(trim(coalesce(account_status, ''))) in ('ACTIVE', 'LEARNING', 'LEARNING LIMITED') then 'ACTIVE'
      when upper(trim(coalesce(account_status, ''))) = 'PAUSED' then 'PAUSED'
      when upper(trim(coalesce(account_status, ''))) in ('ARCHIVED', 'DELETED') then 'ARCHIVED'
      when upper(trim(coalesce(account_status, ''))) = 'SCHEDULED' then 'SCHEDULED'
      when upper(trim(coalesce(account_status, ''))) in ('UNDER REVIEW', 'PENDING REVIEW', 'IN REVIEW') then 'UNDER_REVIEW'
      when upper(trim(coalesce(account_status, ''))) in ('REJECTED', 'DISAPPROVED') then 'REJECTED'
      when upper(trim(coalesce(account_status, ''))) in ('ERROR', 'NO DELIVERY', 'NOT DELIVERING', 'LIMITED DELIVERY') then 'ERROR'
      when upper(trim(coalesce(account_status, ''))) = 'DRAFT' then 'DRAFT'
      when upper(trim(coalesce(account_status, ''))) = 'COMPLETED' then 'COMPLETED'
      else 'UNKNOWN'
    end as account_status_clean,
    
    cast(coalesce(account_status, 'Unknown') as string) as account_status_raw,
    
    -- Currency information
    cast(coalesce(account_currency, currency, 'USD') as string) as account_currency,
    cast(coalesce(currency, account_currency, 'USD') as string) as currency_raw,
    
    -- Campaign aggregation fields
    cast(campaign_statuses as string) as campaign_statuses,
    cast(distinct_campaign_statuses_count as int64) as distinct_campaign_statuses_count,
    cast(has_active_campaigns as boolean) as has_active_campaigns,
    
    case 
      when lower(trim(account_name)) like '%test%' 
        or lower(trim(account_name)) like '%demo%'
        or lower(trim(account_name)) like '%sample%'
        or lower(trim(account_name)) like '%trial%'
        or regexp_contains(lower(trim(account_name)), r'\b(test|demo|sample|trial)\b')
      then true
      else false
    end as is_test_account,
    
    case 
      when account_name is null or trim(account_name) = '' then 'Missing Name'
      when regexp_contains(trim(account_name), r'^[0-9]+$') then 'Numeric Only'
      when length(trim(account_name)) < 3 then 'Too Short'
      else 'Valid'
    end as account_name_quality_flag,
    
    current_timestamp() as _dbt_loaded_at
    
  from unique_accounts
)

select * from cleaned_accounts
where account_id is not null
  and account_id != ''
order by account_name_clean