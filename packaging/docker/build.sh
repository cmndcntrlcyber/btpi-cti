#!/bin/bash
#
# BTPI-CTI Docker Image Build Script
# This script builds the Docker image for the Blue Team Portable Infrastructure - Cyber Threat Intelligence
#

set -e

# Configuration
IMAGE_NAME="cmndcntrlcyber/btpi-cti"
IMAGE_TAG="latest"
DOCKERFILE_PATH="./Dockerfile"
CONTEXT_PATH="../.."

# Display banner
echo "====================================================="
echo "  BTPI-CTI Docker Image Build"
echo "====================================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Parse command line arguments
VERSION=""
PUSH=false

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -v|--version)
            VERSION="$2"
            shift
            shift
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -v, --version VERSION    Set the image version tag (default: latest)"
            echo "  -p, --push               Push the image to Docker Hub after building"
            echo "  -h, --help               Display this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $key"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Set version tag if provided
if [ ! -z "$VERSION" ]; then
    IMAGE_TAG="$VERSION"
fi

# Build the Docker image
echo "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
echo "Using Dockerfile: $DOCKERFILE_PATH"
echo "Build context: $CONTEXT_PATH"
echo ""

docker build -t "$IMAGE_NAME:$IMAGE_TAG" -f "$DOCKERFILE_PATH" "$CONTEXT_PATH"

echo ""
echo "Docker image built successfully: $IMAGE_NAME:$IMAGE_TAG"

# Push the image if requested
if [ "$PUSH" = true ]; then
    echo ""
    echo "Pushing Docker image to Docker Hub..."
    
    # Check if logged in to Docker Hub
    if ! docker info | grep -q "Username"; then
        echo "You are not logged in to Docker Hub."
        echo "Please login using 'docker login' before pushing the image."
        exit 1
    fi
    
    docker push "$IMAGE_NAME:$IMAGE_TAG"
    
    echo "Docker image pushed successfully: $IMAGE_NAME:$IMAGE_TAG"
fi

echo ""
echo "====================================================="
echo "  Build Complete"
echo "====================================================="
echo ""
echo "To run the image:"
echo "  docker run -it --rm $IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "To use with docker-compose:"
echo "  cd $(dirname "$0") && docker-compose up -d"
echo ""

exit 0
