WHERE 1=1
  AND date IS NOT NULL
  AND account_id IS NOT NULL
  AND campaign_id IS NOT NULL
  AND date >= '{{ var("facebook_ads_start_date") }}'
  {% if var("exclude_test_campaigns", true) %}
  AND NOT (
    LOWER(campaign_name) LIKE '%test%' 
    OR LOWER(ad_name) LIKE '%test%'
  )
  {% endif %}
  AND spend >= {{ var("min_spend_threshold", 0) }}