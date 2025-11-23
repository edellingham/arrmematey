#!/bin/bash

echo "🎨 Adding Container Mappings & Professional Icons to UI"
echo "===================================================="

# First, let's find the UI codebase structure
echo "🔍 Checking for UI directory..."
cd /home/ed/Dev/arrmematey

if [ -d "ui" ]; then
    echo "✅ Found UI directory"
    echo "Contents:"
    ls -la ui/ | head -10
    
    echo ""
    echo "📁 Full UI structure:"
    tree ui/ -I node_modules -L 3 2>/dev/null || find ui -type f | head -15
    
    echo ""
    echo "🔍 Looking for main component files..."
    find ui -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.vue" -o -name "*.html" | head -15
    
    echo ""
    echo "📦 Package and config files..."
    find ui -name "package.json" -o -name "tsconfig.json" -o -name "webpack.config.js" -o -name "vite.config.js" -o -name "index.html" | head -10
    
else
    echo "❌ UI directory not found in expected location"
    echo "Looking for frontend code in other locations..."
    
    # Check for other possible UI locations
    find . -name "src" -type d | head -5
    find . -name "client" -type d | head -5
    find . -name "frontend" -type d | head -5
    find . -name "web" -type d | head -5
    
    echo ""
    echo "Looking for React/Vue/Angular files in root..."
    find . -maxdepth 3 -name "*.js" -not -path "./ui/*" | head -10
    find . -maxdepth 3 -name "*.jsx" -not -path "./ui/*" | head -10
    find . -maxdepth 3 -name "*.ts" -not -path "./ui/*" | head -10
    find . -maxdepth 3 -name "*.tsx" -not -path "./ui/*" | head -10
    find . -maxdepth 3 -name "*.vue" -not -path "./ui/*" | head -10
    
    echo ""
    echo "🏠 Current directory structure:"
    ls -la | head -15
fi