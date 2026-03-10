#!/bin/bash

# Tuganire VPS Deployment Script
# Usage: ./deploy.sh

set -e

echo "🚀 Tuganire Production Deployment"
echo "=================================="
echo ""

# Check if running on VPS
if [ ! -f "/etc/os-release" ]; then
    echo "❌ This script should be run on a Linux VPS"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo apt update
    sudo apt install docker-compose -y
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Navigate to docker directory
cd "$(dirname "$0")"

echo ""
echo "🔧 Configuration Check"
echo "====================="
echo ""

# Check if production compose file exists
if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ docker-compose.prod.yml not found"
    exit 1
fi

echo "✅ Production configuration found"
echo ""

# Ask for confirmation
read -p "Deploy to production? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "🏗️  Building and deploying..."
echo ""

# Stop existing containers
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "Stopping existing containers..."
    docker-compose -f docker-compose.prod.yml down
fi

# Build and start
docker-compose -f docker-compose.prod.yml up -d --build

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check status
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "📝 Recent logs:"
docker-compose -f docker-compose.prod.yml logs --tail=20 app

echo ""
echo "✨ Deployment complete!"
echo ""
echo "🌐 Access your application:"
echo "   - HTTP:  http://$(curl -s ifconfig.me)"
echo "   - HTTPS: https://your-domain.com (if configured)"
echo ""
echo "📋 Useful commands:"
echo "   - View logs:    docker-compose -f docker-compose.prod.yml logs -f"
echo "   - Restart:      docker-compose -f docker-compose.prod.yml restart"
echo "   - Stop:         docker-compose -f docker-compose.prod.yml down"
echo ""
