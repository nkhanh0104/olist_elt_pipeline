#!/bin/bash

echo "🚀 Creating virtual environment with Python 3.10..."

python3.10 -m venv .venv
source .venv/bin/activate

echo "⬆️  Upgrading pip, setuptools, wheel..."

pip install --upgrade pip setuptools wheel

echo "📦 Installing required packages..."

pip install -r requirements.txt

echo "✅ Environment setup complete."