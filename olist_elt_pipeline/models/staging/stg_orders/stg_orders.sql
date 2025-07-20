{{
    config(
        materialized='view',
        alias='stg_orders',
        cluster_by=['order_purchase_ts']
    )
}}

-- Normalize columns
WITH casted as(
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('orders')) }}
    FROM {{ source('raw', 'orders') }}
),

-- Filter invalid core fields for join or logic
filtered AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_ts,
        order_approved_ts,
        order_delivered_carrier_ts,
        order_delivered_customer_ts,
        order_estimated_delivery_date
    FROM casted
    WHERE
        order_id IS NOT NULL
        AND customer_id IS NOT NULL
        /* Remove trash customer_id not exist in the parent table */
        AND EXISTS (
            SELECT 1 FROM {{ source('raw', 'customers') }} c
            WHERE c.customer_id = casted.customer_id
        )
        AND order_status IS NOT NULL
        AND order_purchase_ts IS NOT NULL
),

-- Rank record duplicate order_id order by order_purchase_ts
ranked AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_ts,
        order_approved_ts,
        order_delivered_carrier_ts,
        order_delivered_customer_ts,
        order_estimated_delivery_date,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_purchase_ts DESC) AS rn_order_id_duplicate --rank duplicate order_id
    FROM filtered
)

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_ts,
    order_approved_ts,
    {{ flag_missing_column('order_approved_ts') }},
    order_delivered_carrier_ts,
    {{ flag_missing_column('order_delivered_carrier_ts') }},
    order_delivered_customer_ts,
    {{ flag_missing_column('order_delivered_customer_ts') }},
    order_estimated_delivery_date,
    {{ flag_missing_column('order_estimated_delivery_date') }},
FROM ranked
WHERE rn_order_id_duplicate = 1 -- To remove duplicate