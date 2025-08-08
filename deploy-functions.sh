#!/bin/bash

# PrismNg Firebase Functions Deployment Script
# This script sets up and deploys the AI processing functions

set -e

echo "🚀 Starting PrismNg Functions Deployment"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if logged into Firebase
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please login to Firebase:"
    firebase login
fi

# Navigate to functions directory
cd functions

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Check if OpenAI API key is configured
echo "🔑 Checking configuration..."
if ! firebase functions:config:get openai.key &> /dev/null; then
    echo "⚠️  OpenAI API key not configured."
    echo "Please set it with:"
    echo "firebase functions:config:set openai.key=\"your-openai-api-key\""
    echo ""
    read -p "Do you want to set it now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your OpenAI API key: " openai_key
        firebase functions:config:set openai.key="$openai_key"
        echo "✅ OpenAI API key configured"
    else
        echo "❌ Cannot deploy without OpenAI API key"
        exit 1
    fi
fi

# Build the functions
echo "🔨 Building functions..."
npm run build

# Deploy functions
echo "🚀 Deploying functions..."
firebase deploy --only functions

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Available functions:"
echo "- analyzeThought"
echo "- generateAssociations" 
echo "- generateInsight"
echo "- generateEmbedding"
echo "- analyzeEmotionalState"
echo "- batchAnalyze"
echo "- streamChat"
echo ""
echo "🔗 Functions URL: https://us-central1-prismng-app.cloudfunctions.net/"
echo ""
echo "📊 Monitor your functions:"
echo "firebase functions:log"

# Return to root directory
cd ..

echo "🎉 PrismNg AI Functions are now live!"