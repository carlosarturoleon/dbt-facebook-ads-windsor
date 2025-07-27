{{ config(materialized='ephemeral') }}

with insights_base as (
  select 
    -- All original fields from insights staging model
    insights_key,
    date_day,
    account_id,
    account_name,
    campaign_id,
    campaign_name,
    campaign_objective,
    campaign_status,
    ad_id,
    ad_name,
    impressions,
    clicks,
    spend,
    reach,
    frequency,
    cost_per_mille,
    cost_per_click,
    click_through_rate,
    conversions,
    conversion_value,
    cost_per_conversion,
    return_on_ad_spend,
    data_quality_flag,
    _dbt_loaded_at
  from {{ ref('stg_facebook_ads__insights') }}
),

-- Get currency information from campaigns source data
-- Since insights table doesn't have currency, we need to get it from campaigns
campaign_currency_lookup as (
  select distinct
    account_id,
    campaign_id,
    -- Use account_currency first, then currency field as fallback
    coalesce(account_currency, currency, 'USD') as account_currency
  from {{ source('raw_data', 'facebook_ads_windsor_campaigns') }}
  where account_id is not null 
    and campaign_id is not null
),

-- In case we don't have campaign data, create account-level currency lookup
account_currency_lookup as (
  select distinct
    account_id,
    -- Use most common currency for each account
    mode() over (partition by account_id) as account_currency_mode
  from (
    select distinct
      account_id,
      coalesce(account_currency, currency, 'USD') as account_currency
    from {{ source('raw_data', 'facebook_ads_windsor_campaigns') }}
    where account_id is not null
  )
),

insights_with_currency as (
  select 
    i.*,
    
    -- Primary currency lookup from campaign-specific data
    coalesce(
      ccl.account_currency,
      acl.account_currency_mode,
      'USD'  -- Default fallback if no currency information found
    ) as account_currency
    
  from insights_base i
  left join campaign_currency_lookup ccl
    on i.account_id = ccl.account_id 
    and i.campaign_id = ccl.campaign_id
  left join account_currency_lookup acl
    on i.account_id = acl.account_id
),

currency_validated as (
  select
    *,
    
    -- Currency validation
    case 
      when account_currency is null then 'Missing Currency'
      when length(trim(account_currency)) != 3 then 'Invalid Currency Code'
      when upper(account_currency) not in (
        'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CNY', 'INR', 'BRL', 'MXN',
        'KRW', 'SGD', 'HKD', 'NOK', 'SEK', 'DKK', 'CHF', 'PLN', 'CZK', 'HUF',
        'RON', 'BGN', 'HRK', 'RUB', 'TRY', 'ZAR', 'ILS', 'AED', 'SAR', 'QAR',
        'KWD', 'BHD', 'OMR', 'JOD', 'LBP', 'EGP', 'MAD', 'TND', 'DZD', 'NGN',
        'GHS', 'KES', 'UGX', 'TZS', 'ETB', 'XOF', 'XAF', 'ZMW', 'BWP', 'SZL',
        'LSL', 'NAD', 'MWK', 'MZN', 'AOA', 'CDF', 'RWF', 'BIF', 'DJF', 'ERN',
        'STD', 'CVE', 'GMD', 'GNF', 'LRD', 'SLL', 'SHP', 'MVR', 'SCR', 'MUR',
        'KMF', 'MGA', 'YER', 'AFN', 'PKR', 'LKR', 'BDT', 'BTN', 'NPR', 'MMK',
        'LAK', 'KHR', 'VND', 'THB', 'MYR', 'IDR', 'PHP', 'TWD', 'MNT', 'KZT',
        'UZS', 'KGS', 'TJS', 'TMT', 'AZN', 'GEL', 'AMD', 'MDL', 'UAH', 'BYN',
        'RSD', 'MKD', 'ALL', 'BAM', 'EUR'  -- Adding EUR again to handle duplicates
      ) then 'Unsupported Currency'
      else 'Valid Currency'
    end as currency_validation_flag
  from insights_with_currency
),

final_model as (
  select
    -- All original fields from insights
    insights_key,
    date_day,
    account_id,
    account_name,
    campaign_id,
    campaign_name,
    campaign_objective,
    campaign_status,
    ad_id,
    ad_name,
    impressions,
    clicks,
    spend,
    reach,
    frequency,
    cost_per_mille,
    cost_per_click,
    click_through_rate,
    conversions,
    conversion_value,
    cost_per_conversion,
    return_on_ad_spend,
    data_quality_flag,
    _dbt_loaded_at,
    
    -- Currency information
    upper(trim(account_currency)) as account_currency,
    currency_validation_flag,
    
    -- Original currency amounts (for transparency)
    spend as spend_original_currency,
    conversion_value as conversion_value_original_currency,
    cost_per_click as cost_per_click_original_currency,
    cost_per_mille as cost_per_mille_original_currency,
    cost_per_conversion as cost_per_conversion_original_currency
    
    -- Future USD conversion fields (commented out for now)
    /*
    -- These fields will be implemented when exchange rate data is available
    case 
      when account_currency = 'USD' then spend
      when exchange_rate is not null then spend * exchange_rate
      else null
    end as spend_usd,
    
    case 
      when account_currency = 'USD' then conversion_value
      when exchange_rate is not null then conversion_value * exchange_rate
      else null
    end as conversion_value_usd,
    
    case 
      when account_currency = 'USD' then cost_per_click
      when exchange_rate is not null then cost_per_click * exchange_rate
      else null
    end as cost_per_click_usd,
    
    case 
      when account_currency = 'USD' then cost_per_mille
      when exchange_rate is not null then cost_per_mille * exchange_rate
      else null
    end as cost_per_mille_usd,
    
    case 
      when account_currency = 'USD' then cost_per_conversion
      when exchange_rate is not null then cost_per_conversion * exchange_rate
      else null
    end as cost_per_conversion_usd,
    
    -- Exchange rate metadata (for future use)
    exchange_rate,
    exchange_rate_date,
    exchange_rate_source
    */
    
  from currency_validated
)

select * from final_model
where currency_validation_flag = 'Valid Currency'

-- Future framework for USD conversion:
-- 1. Create or source an exchange rates table with daily rates
-- 2. Join on account_currency and date_day
-- 3. Uncomment the USD conversion fields above
-- 4. Add exchange rate quality validations
-- 5. Consider adding exchange rate source documentation