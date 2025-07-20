{{ 
    config(
        materialized='table',
        alias='fct_daily_revenue_by_state'
    )
}}

WITH revenue_base AS (
    SELECT
        order_id,
        customer_id,
        order_purchase_date,
        total_revenue
    FROM {{ ref('int_revenue_base') }}
    WHERE order_status IN ('delivered', 'shipped')
),

-- Join with dim_customer_location to get state
joined_with_dim_customer_location AS (
    SELECT
        r.order_id,
        r.total_revenue,
        r.order_purchase_date,
        l.customer_unique_id,
        l.customer_state
    FROM revenue_base r
    INNER JOIN {{ ref('dim_customer_location') }} l
        ON r.customer_id = l.customer_id
),

-- Join with dim_dates to allow flexible time filtering
joined_with_dates AS (
    SELECT
        l.order_id,
        l.total_revenue,
        l.order_purchase_date,
        l.customer_unique_id,
        l.customer_state,
        d.date_day,
        d.year,
        d.month,
        d.quarter,
    FROM joined_with_dim_customer_location l
    INNER JOIN {{ ref('dim_dates') }} d ON l.order_purchase_date = d.date_day
    {{ filter_by_date_granularity('d') }}
)

SELECT
    customer_state,
    date_day,
    year,
    month,
    quarter,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    SUM(total_revenue) AS total_revenue
FROM joined_with_dates
GROUP BY customer_state, date_day, year, month, quarter
ORDER BY date_day, customer_state