#!/bin/bash

# Wakanda Protocol Quick Start Script
# This script sets up and runs the AI Digital Government Generator

echo "🌍 WAKANDA PROTOCOL - AI DIGITAL GOVERNMENT GENERATOR"
echo "=================================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "Please install Python 3.8+ and try again."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed."
    echo "Please install pip and try again."
    exit 1
fi

echo "✅ pip3 found"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚙️ Creating .env file from template..."
    cp .env.example .env
    echo ""
    echo "🔑 IMPORTANT: Edit .env file with your API keys:"
    echo "   - OPENROUTER_API_KEY (required for AI generation)"
    echo "   - ALPHAVANTAGE_KEY (optional, for economic data)"
    echo "   - WEATHER_API_KEY (optional, for weather data)"
    echo "   - MASTERCARD credentials (optional, for payment data)"
    echo ""
    echo "💡 You can run the system without API keys to test the prediction model."
    echo ""
    read -p "Press Enter to continue..."
fi

# Test the prediction model
echo "🧪 Testing mineral investment prediction model..."
python prediction_model.py

echo ""
echo "🚀 Starting Wakanda Protocol API server..."
echo "📱 Access the API at: http://localhost:8000"
echo "📖 View documentation at: http://localhost:8000/docs"
echo "🌐 View web interface at: http://localhost:8000 (coming soon)"
echo ""
echo "🛑 Press Ctrl+C to stop the server"
echo ""

# Start the server
python generator.py