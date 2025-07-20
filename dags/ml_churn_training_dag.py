from airflow.decorators import dag
from airflow.operators.python import PythonOperator
from airflow.models import Variable
from datetime import datetime, timedelta

import pandas as pd
import joblib
import os
import snowflake.connector
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

default_args={
    'owner': 'airflow',
    'depends_on_past': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

def train_and_upload_model():
    # Load Snowflake credentials from Airflow Variables
    snowflake_config = {
        'user': Variable.get('SNOWFLAKE_USER'),
        'password': Variable.get('SNOWFLAKE_PASSWORD'),
        'account': Variable.get('SNOWFLAKE_ACCOUNT'),
        'warehouse': Variable.get('SNOWFLAKE_WAREHOUSE'),
        'database': Variable.get('SNOWFLAKE_DATABASE'),
        'schema': Variable.get('SNOWFLAKE_SCHEMA_MART'),
        'role': Variable.get('SNOWFLAKE_ROLE'),
    }

    # Generate a timestamp for the model file name
    fileTimestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    model_path = f"/opt/airflow/ml_models/churn_model_{fileTimestamp}.pkl"

    # Connect to Snowflake
    conn = snowflake.connector.connect(**snowflake_config)

    # Query data
    query = 'SELECT * FROM fct_customer_features_ml'
    df = pd.read_sql(query, conn)

    # Lowercase column name for consistency
    df.columns = df.columns.str.lower()

    # Preprocessing
    # Convert to Pandas datetime type
    df['first_purchase_date'] = pd.to_datetime(df['first_purchase_date'])
    df['last_purchase_date'] = pd.to_datetime(df['last_purchase_date'])

    # Convert date columns to date-only format
    # to avoid the error "Binding data in type (timestamp) is not supported."
    # Note: If 
    df['first_purchase_date'] = df['first_purchase_date'].dt.date
    df['last_purchase_date'] = df['last_purchase_date'].dt.date

    X = df.drop(columns=['customer_unique_id', 'first_purchase_date', 'last_purchase_date', 'is_churned'])
    y = df['is_churned']
    extra_fields = df[[
        'customer_unique_id', 'first_purchase_date', 'last_purchase_date',
        'total_orders', 'total_accounts', 'total_revenue',
        'avg_revenue_per_order', 'days_since_last_order'
    ]]

    # Split data: ONLY SPLIT X AND Y
    # The extra_fields_train and extra_fields_test variables will be created from extra_fields
    # based on the indices of X_train and X_test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y # Add stratify to ensure balanced layer distribution
    )

    # Create DataFrame df_result from extra_fields of test set
    # Make sure df_result is initialized BEFORE using
    df_result = extra_fields.loc[X_test.index].copy() # Filter extra_fields by index of X_test

    # Train model
    clf = RandomForestClassifier(n_estimators=100, random_state=42)
    clf.fit(X_train, y_train)

    # Save model
    # Make sure the /opt/airflow/ml_models directory exists in the container
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    joblib.dump(clf, model_path)

    if os.path.exists(model_path):
        print(f"✅ Model trained and saved at: {model_path}")
    else:
        print(f"❌ Model file not saved! Please check file path or permissions.")

    # Predict
    y_proba = clf.predict_proba(X_test)[:, 1]

    # Merge predictions
    df_result['churn_probability'] = y_proba
    df_result['actual_churned'] = y_test.values # y_test is already a Series, .values to ensure array

    # Reorder columns
    df_result = df_result[[
        'customer_unique_id', 'churn_probability', 'actual_churned',
        'first_purchase_date', 'last_purchase_date',
        'total_orders', 'total_accounts', 'total_revenue',
        'avg_revenue_per_order', 'days_since_last_order'
    ]]

    # Create table in Snowflake
    cs = conn.cursor()
    cs.execute("""
        CREATE OR REPLACE TABLE ml_churn_predictions (
            customer_unique_id STRING,
            churn_probability FLOAT,
            actual_churned BOOLEAN,
            first_purchase_date DATE,
            last_purchase_date DATE,
            total_orders INT,
            total_accounts INT,
            total_revenue FLOAT,
            avg_revenue_per_order FLOAT,
            days_since_last_order INT
        )
    """)

    # Insert data
    # Convert DataFrame to list of lists for insert
    insert_query = """
        INSERT INTO ml_churn_predictions (
            customer_unique_id, churn_probability, actual_churned,
            first_purchase_date, last_purchase_date,
            total_orders, total_accounts, total_revenue,
            avg_revenue_per_order, days_since_last_order
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    cs.executemany(insert_query, df_result.values.tolist())
    conn.commit()
    conn.close()

    print(f"✅ Predictions uploaded to Snowflake.")


# Define DAG using decorator style (AIP-48)
@dag(
    dag_id='ml_churn_training_dag',
    default_args=default_args,
    description='Using machine learning to train customer churn prediction',
    schedule_interval='0 5 * * *',  # run daily at 5 AM
    start_date=datetime(2025, 7, 1),
    catchup=False,
    tags=['ml', 'churn', 'snowflake'],
)

def ml_churn_training_dag_pipeline():
    """
    This is the main pipeline definition function of the DAG according to the AIP-48 standard.
    Tasks are defined by directly instantiating the PythonOperator.
    """

    # Instantiate PythonOperator directly.
    # In a function decorated with @dag, operators instantiated this way
    # will automatically be registered as tasks in the DAG.
    train_task = PythonOperator(
        task_id='train_and_upload_churn_model',
        python_callable=train_and_upload_model,
    )

    train_task

# Initialize the DAG by calling the decorated pipeline function
dag = ml_churn_training_dag_pipeline()