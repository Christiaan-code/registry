#!/bin/bash

# Multi-platform Docker Image Builder
# This script builds and pushes images for both ARM64 and AMD64

set -e

echo "🏗️  Multi-Platform Docker Image Builder"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}❌ Docker buildx is not available${NC}"
    echo "Please update Docker to a version that supports buildx"
    exit 1
fi

echo -e "${GREEN}✅ Docker buildx is available${NC}"

# Parse command line arguments
DOCKERFILE="Dockerfile"
BUILD_CONTEXT="."
BUILD_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            DOCKERFILE="$2"
            shift 2
            ;;
        -c|--context)
            BUILD_CONTEXT="$2"
            shift 2
            ;;
        --build-arg)
            BUILD_ARGS="$BUILD_ARGS --build-arg $2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Get parameters
echo ""
read -p "Enter image name (e.g., whatsapp-automation): " IMAGE_NAME
if [ -z "$IMAGE_NAME" ]; then
    echo -e "${RED}❌ Image name cannot be empty${NC}"
    exit 1
fi

read -p "Enter registry URL (default: registry.builtbychristiaan.com): " REGISTRY_URL
REGISTRY_URL=${REGISTRY_URL:-registry.builtbychristiaan.com}

read -p "Enter tag (default: latest): " TAG
TAG=${TAG:-latest}

read -p "Add additional tags? (e.g., v1.0.0, comma-separated, or press Enter to skip): " ADDITIONAL_TAGS

FULL_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}:${TAG}"
TAG_ARGS="--tag ${FULL_IMAGE}"

# Add additional tags if provided
if [ -n "$ADDITIONAL_TAGS" ]; then
    IFS=',' read -ra TAGS <<< "$ADDITIONAL_TAGS"
    for t in "${TAGS[@]}"; do
        t=$(echo "$t" | xargs)  # trim whitespace
        TAG_ARGS="$TAG_ARGS --tag ${REGISTRY_URL}/${IMAGE_NAME}:${t}"
    done
fi

echo ""
echo "📋 Build Configuration:"
echo "======================="
echo "Image: ${FULL_IMAGE}"
if [ -n "$ADDITIONAL_TAGS" ]; then
    echo "Additional tags: ${ADDITIONAL_TAGS}"
fi
echo "Platforms: linux/amd64, linux/arm64"
echo "Dockerfile: ${DOCKERFILE}"
echo "Build context: ${BUILD_CONTEXT}"
if [ -n "$BUILD_ARGS" ]; then
    echo "Build args: ${BUILD_ARGS}"
fi
echo ""

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}❌ Dockerfile not found: ${DOCKERFILE}${NC}"
    exit 1
fi

# Check if logged into registry
echo "🔐 Checking registry authentication..."
if ! docker login "${REGISTRY_URL}" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to ${REGISTRY_URL}${NC}"
    echo "Please login to your registry:"
    docker login "${REGISTRY_URL}"
fi

echo -e "${GREEN}✅ Authenticated with registry${NC}"

# Create buildx builder if it doesn't exist
echo ""
echo "🔧 Setting up buildx builder..."
if ! docker buildx inspect multiplatform-builder &> /dev/null; then
    docker buildx create --name multiplatform-builder --driver docker-container --use
    echo -e "${GREEN}✅ Created multiplatform-builder${NC}"
else
    docker buildx use multiplatform-builder
    echo -e "${GREEN}✅ Using existing multiplatform-builder${NC}"
fi

# Bootstrap the builder
docker buildx inspect --bootstrap

echo ""
read -p "Ready to build and push? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Build cancelled"
    exit 0
fi

echo ""
echo "🚀 Building multi-platform image..."
echo -e "${BLUE}This may take a while...${NC}"
echo ""

# Build and push
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    ${TAG_ARGS} \
    ${BUILD_ARGS} \
    --file "${DOCKERFILE}" \
    --push \
    --progress=plain \
    "${BUILD_CONTEXT}"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Multi-platform image built and pushed successfully!${NC}"
    echo ""
    echo "📊 Image details:"
    echo "   ${FULL_IMAGE}"
    if [ -n "$ADDITIONAL_TAGS" ]; then
        IFS=',' read -ra TAGS <<< "$ADDITIONAL_TAGS"
        for t in "${TAGS[@]}"; do
            t=$(echo "$t" | xargs)
            echo "   ${REGISTRY_URL}/${IMAGE_NAME}:${t}"
        done
    fi
    echo ""
    echo "🔍 Verify platforms:"
    echo "   docker manifest inspect ${FULL_IMAGE}"
    echo ""
    echo "📥 Pull on any platform:"
    echo "   docker pull ${FULL_IMAGE}"
else
    echo ""
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
