#!/bin/bash
# Quick Start Script for Tiannara SaaS Production Deployment
# This script sets up the basic infrastructure for local testing

set -e

echo "🚀 Tiannara SaaS Production Deployment - Quick Start"
echo "======================================================"
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose found"
echo ""

# Create .env file from example
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  IMPORTANT: Edit .env file with your actual credentials before proceeding!"
    echo "   Required: JWT_SECRET_KEY, OPENAI_API_KEY, RESEND_API_KEY, OAuth credentials"
    echo ""
    read -p "Press Enter after you've updated .env with your credentials..."
else
    echo "✅ .env file already exists"
fi

# Build Docker images
echo ""
echo "📦 Building Docker images..."
docker-compose build

# Start services
echo ""
echo "🚀 Starting Tiannara services..."
docker-compose up -d

# Wait for services to be healthy
echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check service health
echo ""
echo "🔍 Checking service health..."
docker-compose ps

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Service URLs:"
echo "   API Backend: http://localhost:8000"
echo "   API Docs:    http://localhost:8000/docs"
echo "   Database:    localhost:5432"
echo "   Redis:       localhost:6379"
echo ""
echo "🧪 Test the API:"
echo "   curl http://localhost:8000/api/v1/health"
echo ""
echo "📝 View logs:"
echo "   docker-compose logs -f tiannara-api"
echo ""
echo "🛑 Stop services:"
echo "   docker-compose down"
echo ""
echo "Next steps:"
echo "   1. Visit http://localhost:8000/docs to explore API endpoints"
echo "   2. Configure OAuth providers in .env"
echo "   3. Set up SSL certificates for production"
echo "   4. Review PRODUCTION_DEPLOYMENT_GUIDE.md for full deployment"
