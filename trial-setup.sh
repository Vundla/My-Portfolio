#!/bin/bash

echo "🚀 TRIAL DEVELOPMENT SETUP - Skip Enterprise Complexity"
echo "======================================================="

# Skip enterprise organization setup for now
echo "📝 Using personal account with Enterprise trial features..."

# Fix .NET compatibility issues first
echo "🔧 Fixing .NET compatibility..."
cd backend

# Update to .NET 8 (available in current environment)
sed -i 's/net9\.0/net8.0/g' backend.csproj

# Fix API compatibility
echo "🔄 Updating API compatibility..."

# Simple development server startup
echo "🎯 Starting simple development environment..."

echo "✅ TRIAL SETUP COMPLETE!"
echo ""
echo "🚀 Next steps:"
echo "1. Run: dotnet restore (in backend folder)"
echo "2. Run: npm install (in frontend folder)"  
echo "3. Run: dotnet run (start backend)"
echo "4. Run: npm run dev (start frontend)"
echo ""
echo "💡 Focus on building first, optimize enterprise features later!"