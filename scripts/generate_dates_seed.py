import pandas as pd
import os
import sys
from datetime import datetime
def generate_dates_seed(start_date: str, end_date: str, output_path: str):
   """
   Generates a date dimension CSV between start_date and end_date (inclusive).
   Parameters:
       start_date (str): Start date in format YYYY-MM-DD
       end_date (str): End date in format YYYY-MM-DD
       output_path (str): Output path to CSV file
   """
   # Parse dates
   start = pd.to_datetime(start_date)
   end = pd.to_datetime(end_date)
   # Create date range
   df = pd.DataFrame({'date_day': pd.date_range(start=start, end=end)})
   # Add useful date attributes
   # date_day will be the primary key due to its uniqueness
   df['date_day'] = df['date_day'].dt.date
   df['year'] = pd.to_datetime(df['date_day']).dt.year
   df['month'] = pd.to_datetime(df['date_day']).dt.month
   df['day'] = pd.to_datetime(df['date_day']).dt.day
   df['day_of_week'] = pd.to_datetime(df['date_day']).dt.dayofweek  # Monday=0, Sunday=6
   df['day_name'] = pd.to_datetime(df['date_day']).dt.day_name()
   df['week'] = pd.to_datetime(df['date_day']).dt.isocalendar().week
   df['quarter'] = pd.to_datetime(df['date_day']).dt.quarter
   df['is_weekend'] = df['day_of_week'] >= 5
   df['is_month_start'] = pd.to_datetime(df['date_day']).dt.is_month_start
   df['is_month_end'] = pd.to_datetime(df['date_day']).dt.is_month_end
   df['is_quarter_start'] = pd.to_datetime(df['date_day']).dt.is_quarter_start
   df['is_quarter_end'] = pd.to_datetime(df['date_day']).dt.is_quarter_end
   # Create directory if needed
   output_dir = os.path.dirname(os.path.abspath(output_path))
   os.makedirs(output_dir, exist_ok=True)
   # Export to CSV
   df.to_csv(output_path, index=False)
   print(f"✅ Date dimension generated: {output_path}")

if __name__ == "__main__":
   if len(sys.argv) != 4:
       print(f"🔧 Usage: scripts/python generate_dates_seed.py <start_date> <end_date> <output_path>")
       print(f"📌 Example: scripts/python generate_dates_seed.py 2016-01-01 2018-12-31 olist_elt_pipeline/seeds/dim_dates.csv")
       sys.exit(1)
   start = sys.argv[1]
   end = sys.argv[2]
   out_path = sys.argv[3]
   generate_dates_seed(start, end, out_path)