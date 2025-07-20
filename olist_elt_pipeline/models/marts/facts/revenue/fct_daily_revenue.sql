{{ 
    config(
        materialized='table',
        alias='fct_daily_revenue'
    )
}}

WITH revenue_base AS (
    SELECT
        order_id,
        order_purchase_date,
        total_revenue
    FROM {{ ref('int_revenue_base') }}
    WHERE order_status IN ('delivered', 'shipped')
),

-- Join with dim_dates to support flexible time filtering (day, month, quarter, year)
joined_with_dates AS (
    SELECT
        d.date_day,
        d.year,
        d.month,
        d.quarter,
        r.order_id,
        r.total_revenue
    FROM revenue_base r
    INNER JOIN {{ ref('dim_dates') }} d ON r.order_purchase_date = d.date_day
    {{ filter_by_date_granularity('d') }}
)

SELECT
    date_day,
    year,
    month,
    quarter,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_revenue) AS total_revenue
FROM joined_with_dates
GROUP BY date_day, year, month, quarter
ORDER BY date_day