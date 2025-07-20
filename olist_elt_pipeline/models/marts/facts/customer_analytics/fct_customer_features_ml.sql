{{ 
    config(
        materialized='table',
        alias='fct_customer_features_ml'
    )
}}

WITH revenue_base AS (
    SELECT
        customer_id,
        order_id,
        order_purchase_date,
        total_revenue
    FROM {{ ref('int_revenue_base') }}
    WHERE order_status IN ('delivered', 'shipped')
),

joined_with_dim_customer_location AS (
    SELECT
        r.customer_id,
        c.customer_unique_id,
        r.order_id,
        r.order_purchase_date,
        r.total_revenue
    FROM revenue_base r
    INNER JOIN {{ ref('dim_customer_location') }} c ON r.customer_id = c.customer_id
),

aggregated_features AS (
    SELECT
        customer_unique_id,
        MIN(order_purchase_date) AS first_purchase_date,
        MAX(order_purchase_date) AS last_purchase_date,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_accounts,
        -- Calculate the number of days since the customer's last order
        -- This is a key 'recency' feature for churn prediction
        /* 
        Note: The subquery SELECT MAX(order_purchase_date) FROM {{ ref('int_revenue_base') }}
        gets the latest order date available across the entire dataset.
        This represents the 'current' date for churn calculation,
        meaning how many days have passed since the customer's last order
        relative to the freshest data point in the system.
        You can replace subquery SELECT MAX(order_purchase_date) FROM {{ ref('int_revenue_base') }} 
        by CURRENT_DATE if your dataset is real-time
        */
        DATEDIFF(DAY, last_purchase_date, (SELECT MAX(order_purchase_date) FROM {{ ref('int_revenue_base') }})) AS days_since_last_order,
        SUM(total_revenue) AS total_revenue,
        AVG(total_revenue) AS avg_revenue_per_order
    FROM joined_with_dim_customer_location
    GROUP BY customer_unique_id
)

SELECT
    customer_unique_id,
    first_purchase_date,
    last_purchase_date,
    -- Frequency
    total_orders,
    total_accounts,
    -- Monetary
    total_revenue,
    avg_revenue_per_order,
    -- Recency
    days_since_last_order,
    -- Flag customers as 'churned' if they haven't made a purchase for more than 60 days
    -- The 60-day threshold is an example; it might be adjusted based on business logic
    CASE 
        WHEN DATEDIFF(DAY, last_purchase_date, (SELECT MAX(order_purchase_date) FROM {{ ref('int_revenue_base') }})) > 60 
            THEN TRUE ELSE FALSE 
    END AS is_churned
    FROM aggregated_features
