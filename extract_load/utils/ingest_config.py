import os
# --------------- TABLE LIST ---------------
# List of all logical table names (used throughout the pipeline)
table_list = [
    "customers",
    "geolocation",
    "order_items",
    "order_payments",
    "order_reviews",
    "orders",
    "products",
    "sellers",
    "product_category_name_translation"
]

# --- GET PROJECT_ROOT_DIR FROM ENVIRONMENT VARIABLE ---
# This variable is exported from ingest_all.sh
# Safe default if variable does not exist (e.g. run ingest_config.py directly)
PROJECT_ROOT_DIR = os.getenv("PROJECT_ROOT_DIR", os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

# Build the path to the 'data' directory
# os.path.join will handle slashes properly for different OSs, then add os.sep making sure there is a / at the end
BASE_DATA_PATH = os.path.join(PROJECT_ROOT_DIR, "data") + os.sep

# --------------- FILE MAP ---------------
# Map each table name o its correcsponding raw CSV file path.
file_map = {
    "customers": f"{BASE_DATA_PATH}olist_customers_dataset.csv",
    "geolocation": f"{BASE_DATA_PATH}olist_geolocation_dataset.csv",
    "order_items": f"{BASE_DATA_PATH}olist_order_items_dataset.csv",
    "order_payments": f"{BASE_DATA_PATH}olist_order_payments_dataset.csv",
    "order_reviews": f"{BASE_DATA_PATH}olist_order_reviews_dataset.csv",
    "orders": f"{BASE_DATA_PATH}olist_orders_dataset.csv",
    "products": f"{BASE_DATA_PATH}olist_products_dataset.csv",
    "sellers": f"{BASE_DATA_PATH}olist_sellers_dataset.csv",
    "product_category_name_translation": f"{BASE_DATA_PATH}product_category_name_translation.csv"
}