#!/bin/bash

# Railway.app Flutter Web Build Script
# This script ensures environment variables are properly passed to the Flutter build

echo "🚀 Building Flutter Web app for Railway deployment..."

# Check if required environment variables are set
if [ -z "$KIE_AI_API_KEY" ]; then
    echo "⚠️  Warning: KIE_AI_API_KEY environment variable not set"
fi

if [ -z "$SUPABASE_URL" ]; then
    echo "⚠️  Warning: SUPABASE_URL environment variable not set"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "⚠️  Warning: SUPABASE_ANON_KEY environment variable not set"
fi

# Build Flutter web with environment variables as dart-define flags
flutter build web \
  --dart-define=KIE_AI_API_KEY="$KIE_AI_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=RAILWAY_STATIC_URL="$RAILWAY_STATIC_URL" \
  --dart-define=CUSTOM_DOMAIN="$CUSTOM_DOMAIN" \
  --release

echo "✅ Flutter web build completed!"
echo "📁 Build output is in: build/web/"
echo "🌐 Deploy the build/web/ directory to your web server"

# Display environment variable status
echo ""
echo "📋 Environment Variables Status:"
echo "  KIE_AI_API_KEY: ${KIE_AI_API_KEY:+SET}${KIE_AI_API_KEY:-NOT SET}"
echo "  SUPABASE_URL: ${SUPABASE_URL:+SET}${SUPABASE_URL:-NOT SET}"
echo "  SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:+SET}${SUPABASE_ANON_KEY:-NOT SET}"
echo "  RAILWAY_STATIC_URL: ${RAILWAY_STATIC_URL:+SET}${RAILWAY_STATIC_URL:-NOT SET}"