{{ 
    config(
        materialized='view',
        alias='stg_order_payments'
    )
}}

-- Normalize columns
WITH casted AS(
    SELECT
        {{ cast_columns_from_schema(get_staging_schema_map('order_payments')) }}
    FROM {{ source('raw', 'order_payments') }}
)

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM casted
WHERE
    order_id IS NOT NULL
    AND EXISTS (
            SELECT 1 FROM {{ source('raw', 'orders') }} o
            WHERE o.order_id = casted.order_id
        )
    AND payment_sequential IS NOT NULL
    AND payment_sequential >= 1 -- Ensure payment_sequential is at least 1
    AND payment_type IS NOT NULL
    AND payment_installments IS NOT NULL
    AND payment_installments >= 0 -- Ensure payment_installments is non-negative
    AND payment_value IS NOT NULL
    AND payment_value >= 0.00