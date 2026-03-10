#!/bin/bash

# Tuganire Update Script
# Usage: ./update.sh

set -e

echo "🔄 Updating Tuganire..."
echo ""

cd "$(dirname "$0")/.."

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# Navigate to docker directory
cd tuganire-docker

# Rebuild and restart
echo "🏗️  Rebuilding containers..."
docker-compose -f docker-compose.prod.yml up -d --build

echo ""
echo "⏳ Waiting for services to restart..."
sleep 10

# Show status
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "📝 Recent logs:"
docker-compose -f docker-compose.prod.yml logs --tail=20 app

echo ""
echo "✅ Update complete!"
echo ""
