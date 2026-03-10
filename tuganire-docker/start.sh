#!/bin/bash

# Tuganire Docker Quick Start Script

set -e

echo "🚀 Starting Tuganire with Docker..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if tuganire.env exists
if [ ! -f "tuganire.env" ]; then
    echo "❌ tuganire.env not found. Please create it first."
    exit 1
fi

# Build and start services
echo "📦 Building and starting services..."
docker-compose up -d --build

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Wait for database
echo "🗄️  Waiting for database..."
until docker-compose exec -T db pg_isready -U tuganire_user -d tuganire > /dev/null 2>&1; do
    echo "   Database is starting..."
    sleep 2
done
echo "✅ Database is ready!"

# Wait for app
echo "🌐 Waiting for application..."
sleep 10
until curl -f http://localhost:8080/ > /dev/null 2>&1; do
    echo "   Application is starting..."
    sleep 3
done
echo "✅ Application is ready!"

echo ""
echo "✨ Tuganire is running!"
echo ""
echo "📍 Access points:"
echo "   - Application (via nginx): http://localhost"
echo "   - Application (direct):    http://localhost:8080"
echo "   - Database:                localhost:5432"
echo ""
echo "📋 Useful commands:"
echo "   - View logs:        docker-compose logs -f"
echo "   - Stop services:    docker-compose down"
echo "   - Restart:          docker-compose restart"
echo ""
