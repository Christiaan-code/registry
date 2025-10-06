#!/bin/bash

# Docker Registry Setup Script
# This script sets up authentication and initializes the registry

set -e

echo "🚀 Docker Registry Setup"
echo "========================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is installed${NC}"

# Create necessary directories
echo ""
echo "📁 Creating directories..."
mkdir -p auth
mkdir -p data
mkdir -p config
mkdir -p logs

echo -e "${GREEN}✅ Directories created${NC}"

# Prompt for username and password
echo ""
echo "🔐 Setting up authentication..."
echo ""

read -p "Enter registry username (default: admin): " USERNAME
USERNAME=${USERNAME:-admin}

read -sp "Enter registry password: " PASSWORD
echo ""

if [ -z "$PASSWORD" ]; then
    echo -e "${RED}❌ Password cannot be empty${NC}"
    exit 1
fi

# Generate htpasswd file
echo ""
echo "🔑 Generating authentication file..."

docker run --rm --entrypoint htpasswd httpd:2 -Bbn "$USERNAME" "$PASSWORD" > auth/htpasswd

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Authentication file created${NC}"
else
    echo -e "${RED}❌ Failed to create authentication file${NC}"
    exit 1
fi

# Set proper permissions
chmod 600 auth/htpasswd

echo ""
echo "📋 Setup Summary:"
echo "=================="
echo "Username: $USERNAME"
echo "Password: ********"
echo "Auth file: auth/htpasswd"
echo ""

# Ask if user wants to start the registry
echo ""
read -p "Do you want to start the registry now? (y/n): " START_NOW

if [ "$START_NOW" = "y" ] || [ "$START_NOW" = "Y" ]; then
    echo ""
    echo "🚀 Starting Docker Registry..."
    docker-compose up -d
    
    echo ""
    echo "⏳ Waiting for registry to be ready..."
    sleep 5
    
    # Check if registry is running
    if docker ps | grep -q docker-registry; then
        echo -e "${GREEN}✅ Registry is running!${NC}"
        echo ""
        echo "📊 Registry Status:"
        docker-compose ps
        echo ""
        echo "🔗 Registry URL: http://localhost:5000"
        echo ""
        echo "📝 To test your registry:"
        echo "   docker login localhost:5000 -u $USERNAME"
        echo "   docker pull ubuntu"
        echo "   docker tag ubuntu localhost:5000/ubuntu"
        echo "   docker push localhost:5000/ubuntu"
        echo ""
        echo "📖 View logs:"
        echo "   docker-compose logs -f"
        echo ""
        echo "🛑 Stop registry:"
        echo "   docker-compose down"
    else
        echo -e "${RED}❌ Registry failed to start. Check logs with: docker-compose logs${NC}"
        exit 1
    fi
else
    echo ""
    echo "ℹ️  To start the registry later, run:"
    echo "   docker-compose up -d"
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
