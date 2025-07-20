#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the absolute path of the current script directory (project root in Docker)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# *** Important: Set PYTHONPATH so Python finds modules ***
# Add the project root directory (/opt/airflow in Docker) to PYTHONPATH.
# This allows Python to find 'extract_load' and 'dbt' as top-level packages.
export PYTHONPATH="${SCRIPT_DIR}:${PYTHONPATH}"

# Export SCRIPT_DIR as an environment variable so that child Python scripts can read it
export PROJECT_ROOT_DIR="${SCRIPT_DIR}" # Rename to PROJECT_ROOT_DIR for clarity

# Setup log folder
LOG_DIR="logs"
mkdir -p $LOG_DIR
SUCCESS_LOG="$LOG_DIR/success.log"
FAILED_LOG="$LOG_DIR/failed.log"
RUN_LOG="$LOG_DIR/run.log"

# Clear previous logs
> $SUCCESS_LOG
> $FAILED_LOG
> $RUN_LOG

# Load table list from ingest_config.py
TABLES=$(python3 -c "from extract_load.utils.ingest_config import table_list; print(' '.join(table_list))")
# Run ingest for each table
for table in $TABLES; do
   TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
   echo "$TIMESTAMP - 🔄 Ingesting table: $table" | tee -a $RUN_LOG

   # Load CSV file path from ingest_config.py
   CSV_FILE=$(python3 -c "from extract_load.utils.ingest_config import file_map; print(file_map['$table'])")
   if [ ! -f "$CSV_FILE" ]; then
       echo "$TIMESTAMP ❌ Missing file: $CSV_FILE" | tee -a $FAILED_LOG >> $RUN_LOG
       continue
   fi
   # Run PySpark script
   python3 "$PROJECT_ROOT_DIR/extract_load/spark_ingest_generic.py" "$table" "$CSV_FILE" >> $RUN_LOG 2>&1
   # Log result
   if [ $? -eq 0 ]; then
       echo "$TIMESTAMP ✅ $table" | tee -a $SUCCESS_LOG >> $RUN_LOG
   else
       echo "$TIMESTAMP ❌ $table" | tee -a $FAILED_LOG >> $RUN_LOG
   fi
   echo "-------------------------------------------" >> $RUN_LOG
done
# Final summary
echo ""
echo "🎯 Ingest Summary:"
echo "-------------------------"
echo "✅ Success:"
cat $SUCCESS_LOG
echo ""
echo "❌ Failed:"
cat $FAILED_LOG
echo ""
echo "📁 Full log saved in: $RUN_LOG"

echo "🚀 Ingest completed. Check logs for details."