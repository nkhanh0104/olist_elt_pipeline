{% macro get_staging_schema_map(table_name) %}
   {# This macro returns a dictionary mapping table names to their respective schemas.
      Each key is a table name, and the value is a dictionary of column names and their types.
      The types can be simple strings or dictionaries with 'type' and 'alias' keys for more complex types.
    #}
   {% set schema_dict = {
       'customers': {
           "customer_id": "varchar",
           "customer_unique_id": "varchar",
           "customer_zip_code_prefix": "varchar",
           "customer_city": "varchar",
           "customer_state": "varchar"
       },

       'order_items': {
           "order_id": "varchar",
           "order_item_id": "int",
           "product_id": "varchar",
           "seller_id": "varchar",
           "shipping_limit_date": {"type": "timestamp", "alias": "shipping_limit_ts"},
           "price": "numeric(18,2)",
           "freight_value": "numeric(18,2)"
       },

       'order_payments': {
           "order_id": "varchar",
           "payment_sequential": "int",
           "payment_type": "varchar",
           "payment_installments": "int",
           "payment_value": "numeric(18,2)"
       },

       'order_reviews': {
           "review_id": "varchar",
            "order_id": "varchar",
            "review_score": "int",
            "review_comment_title": "varchar",
            "review_comment_message": "varchar",
            "review_creation_date": {"type": "date", "alias": "review_creation_date"},
            "review_answer_timestamp": {"type": "timestamp", "alias": "review_answer_ts"}
       },

       'orders': {
           "order_id": "varchar",
           "customer_id": "varchar",
           "order_status": "varchar",
           "order_purchase_timestamp": {"type": "timestamp", "alias": "order_purchase_ts"},
           "order_approved_at": {"type": "timestamp", "alias": "order_approved_ts"},
           "order_delivered_carrier_date": {"type": "timestamp", "alias": "order_delivered_carrier_ts"},
           "order_delivered_customer_date": {"type": "timestamp", "alias": "order_delivered_customer_ts"},
           "order_estimated_delivery_date": {"type": "date", "alias": "order_estimated_delivery_date"}
       },

       
       'product_category_name_translation': {
           "product_category_name": "varchar",
           "product_category_name_english": "varchar"
       },

       'products': {
           "product_id": "varchar",
           "product_category_name": "varchar",
           "product_name_lenght": {"type": "int", "alias": "product_name_length"},
           "product_description_lenght": {"type": "int", "alias": "product_description_length"},
           "product_photos_qty": "int",
           "product_weight_g": "int",
           "product_length_cm": "int",
           "product_height_cm": "int",
           "product_width_cm": "int"
       },

       'sellers': {
           "seller_id": "varchar",
           "seller_zip_code_prefix": "varchar",
           "seller_city": "varchar",
           "seller_state": "varchar"
       }

   } %}
   {{ return(schema_dict[table_name]) }}
{% endmacro %}