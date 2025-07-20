{{ 
    config(
        materialized='table',
        alias='fct_daily_product_popularity'
    )
}}

WITH revenue_base AS (
    SELECT
        product_id,
        order_purchase_date,
        total_revenue
    FROM {{ ref('int_revenue_base') }}
    WHERE order_status IN ('delivered', 'shipped')
),

joined_with_products AS (
    SELECT
        r.product_id,
        d.product_category_name,
        d.product_category_name_english,
        r.order_purchase_date,
        r.total_revenue
    FROM revenue_base r
    LEFT JOIN {{ ref('dim_product_details') }} d ON r.product_id = d.product_id
),

joined_with_dates AS (
    SELECT
        p.product_id,
        p.product_category_name,
        p.product_category_name_english,
        d.date_day,
        d.year,
        d.month,
        d.quarter,
        p.total_revenue
    FROM joined_with_products p
    INNER JOIN {{ ref('dim_dates') }} d ON p.order_purchase_date = d.date_day
    {{ filter_by_date_granularity('d') }}
)

SELECT
    product_id,
    product_category_name,
    product_category_name_english,
    date_day,
    year,
    month,
    quarter,
    COUNT(*) AS total_quantity_sold,
    SUM(total_revenue) AS total_revenue
FROM joined_with_dates
GROUP BY product_id, product_category_name, product_category_name_english, date_day, year, month, quarter
ORDER BY total_revenue DESC