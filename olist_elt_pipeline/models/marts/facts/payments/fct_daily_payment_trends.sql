{{ 
    config(
        materialized='table',
        alias='fct_daily_payment_trends'
    )
}}

WITH revenue_base AS (
    SELECT
        order_id,
        payment_type,
        order_purchase_date,
        total_revenue
    FROM {{ ref('int_revenue_base') }}
    WHERE order_status IN ('delivered', 'shipped')
),

joined_with_dates AS (
    SELECT
        r.payment_type,
        r.order_id,
        r.total_revenue,
        d.date_day,
        d.year,
        d.month,
        d.quarter
    FROM revenue_base r
    INNER JOIN {{ ref('dim_dates') }} d ON r.order_purchase_date = d.date_day
    {{ filter_by_date_granularity('d') }}
)

SELECT
    payment_type,
    date_day,
    year,
    month,
    quarter,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_revenue) AS total_revenue
FROM joined_with_dates
GROUP BY payment_type, date_day, year, month, quarter
ORDER BY total_orders DESC