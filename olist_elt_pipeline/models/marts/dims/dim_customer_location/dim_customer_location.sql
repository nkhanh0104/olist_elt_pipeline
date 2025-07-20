{{
    config(
        materialized='table',
        alias='dim_customer_location',
    )
}}

SELECT
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
FROM {{ ref('stg_customers') }}