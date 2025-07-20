{{
    config(
        materialized='table',
        alias='int_revenue_base'
    )
}}

-- Base CTEs from cleaned staging
WITH base_orders AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_ts,
        order_approved_ts,
        order_delivered_carrier_ts,
        order_delivered_customer_ts,
        order_estimated_delivery_date,
        is_missing_order_approved_ts,
        is_missing_order_delivered_carrier_ts,
        is_missing_order_delivered_customer_ts,
        is_missing_order_estimated_delivery_date
    FROM {{ ref('stg_orders') }}
),

base_order_items AS (
    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        price,
        freight_value,
        is_duplicate_order_item_sk -- kept to trace if necessary
    FROM {{ ref('stg_order_items') }}
),

-- Aggregate total payment value per order to avoid duplication when joining 
base_payment_agg AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),

-- Select the first payment row per order to get payment_type and installments
base_payment_first AS (
    SELECT
        order_id,
        payment_type,
        payment_installments,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY payment_sequential) AS rn
    FROM {{ ref('stg_order_payments') }}
),

-- Final payment CTE combining total value and descriptive fields
base_order_payments AS (
    SELECT
        pf.order_id,
        pf.payment_type,
        pf.payment_installments,
        pa.payment_value
    FROM base_payment_first pf
    INNER JOIN base_payment_agg pa ON pf.order_id = pa.order_id
    WHERE pf.rn = 1
)

SELECT
    o.order_id,
    o.customer_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,

    -- Order information
    o.order_status,
    o.order_purchase_ts,
    o.order_approved_ts,
    o.order_delivered_carrier_ts,
    o.order_delivered_customer_ts,
    o.order_estimated_delivery_date,
    DATE(o.order_purchase_ts) AS order_purchase_date,

    -- Payment information
    p.payment_type,
    p.payment_installments,
    p.payment_value,

    -- Price information
    oi.price,
    oi.freight_value,
    -- Total revenue logic:
    -- If order has payment_value (actual paid), use it.
    -- Else, fallback to listed price + freight_value (approx revenue).
    -- Helps preserve orders paid via 100% voucher or missing payment record.
    COALESCE(p.payment_value, oi.price + oi.freight_value) AS total_revenue,

    -- Flag information (reused from staging)
    o.is_missing_order_approved_ts,
    o.is_missing_order_delivered_carrier_ts,
    o.is_missing_order_delivered_customer_ts,
    o.is_missing_order_estimated_delivery_date,

    -- Trace
    oi.is_duplicate_order_item_sk
FROM base_orders o
-- We ensure only orders with value items are included in the mart
INNER JOIN base_order_items oi ON o.order_id = oi.order_id
-- Some orders may have missing payment records.
-- We fallback to price + freight_value in total_revenue, so we preserve such rows for completeness.
INNER JOIN base_order_payments p ON o.order_id = p.order_id
