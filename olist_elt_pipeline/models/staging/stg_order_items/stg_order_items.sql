{{ 
    config(
        materialized='view',
        alias='stg_order_items'
    )
}}

-- Normalize columns
WITH casted AS (
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('order_items')) }}
    FROM {{ source('raw', 'order_items') }}
),

-- Filter invalid core fields for join or logic
filtered AS (
    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_ts,
        price,
        freight_value
    FROM casted
    WHERE
        order_id IS NOT NULL
        /* Remove trash order_id not exist in the parent table */
        AND EXISTS (
            SELECT 1 FROM {{ source('raw', 'orders') }} o
            WHERE o.order_id = casted.order_id
        )
        AND order_item_id IS NOT NULL
        AND order_item_id >= 1 -- Ensoure order_item_id at least 1
        AND product_id IS NOT NULL
        /* Remove trash product_id not exist in the parent table */
        AND EXISTS (
            SELECT 1 FROM {{ source('raw', 'products') }} p
            WHERE p.product_id = casted.product_id
        )
        AND seller_id IS NOT NULL
        /* Remove trash seller_id not exist in the parent table */
        AND EXISTS (
            SELECT 1 FROM {{ source('raw', 'sellers') }} s
            WHERE s.seller_id = casted.seller_id
        )
        AND shipping_limit_ts IS NOT NULL
        AND price IS NOT NULL
        AND price > 0.00 -- Ensure price is greater than 0
        AND freight_value IS NOT NULL
        AND freight_value >= 0.00 -- Ensure freight_value is non-negative
),

-- Create surrogate key
with_sk AS (
    SELECT
        -- Surrogate key combine from order_id, order_item_id and shipping_limit_ts
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id', 'shipping_limit_ts']) }} AS order_item_sk,
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_ts,
        price,
        freight_value
    FROM filtered
),

-- Rank record duplicate order_item_sk order by shipping_limit_ts
ranked AS (
    SELECT
        order_item_sk,
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_ts,
        price,
        freight_value,
        ROW_NUMBER() OVER(PARTITION BY order_item_sk ORDER BY shipping_limit_ts) AS rn_order_item_sk_duplicate  --rank duplicate order_item_sk
    FROM with_sk
),

-- Add flag to check missing and duplicated for another fill can use to analyze
flagged AS (
    SELECT
        order_item_sk,
        {{ flag_duplicate_column('order_item_sk', 'is_duplicate_order_item_sk') }},
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_ts,
        price,
        freight_value,
        rn_order_item_sk_duplicate  --rank duplicate order items with the same sk
    FROM ranked
)

/* Select only the first rn_order_item_sk_duplicate to deduplicate */
SELECT
    order_item_sk,
    is_duplicate_order_item_sk, -- kept to trace if necessary
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_ts,
    price,
    freight_value
FROM flagged
WHERE
    rn_order_item_sk_duplicate = 1