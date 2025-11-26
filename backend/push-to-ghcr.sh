#!/bin/bash
# Script to push VendingBackpack backend to GitHub Container Registry (GHCR)

set -e

# Configuration
GITHUB_ORG="aldervon-systems"  # Must be lowercase for Docker
REPOSITORY_NAME="vendingbackpack"
IMAGE_TAG="latest"
LOCAL_IMAGE="vending-backend:latest"
GHCR_IMAGE="ghcr.io/${GITHUB_ORG}/${REPOSITORY_NAME}:${IMAGE_TAG}"

echo "🚀 Pushing VendingBackpack Backend to GHCR"
echo "==========================================="
echo ""

# Check if local image exists
if ! sudo docker image inspect ${LOCAL_IMAGE} &> /dev/null; then
    echo "❌ Error: Local image '${LOCAL_IMAGE}' not found!"
    echo "Please build the image first with: sudo docker build -t vending-backend:latest ."
    exit 1
fi

echo "✓ Local image found: ${LOCAL_IMAGE}"
echo ""

# Check if already logged in to GHCR
if ! sudo docker info 2>/dev/null | grep -q "ghcr.io"; then
    echo "🔐 Please login to GitHub Container Registry"
    echo "You'll need a GitHub Personal Access Token (PAT) with 'write:packages' permission"
    echo ""
    echo "Create one at: https://github.com/settings/tokens/new"
    echo "Required scopes: write:packages, read:packages"
    echo ""
    echo "Note: You must have access to the '${GITHUB_ORG}' organization"
    echo ""
    read -p "Enter your GitHub username: " github_username
    read -sp "Enter your Personal Access Token (PAT): " github_token
    echo ""
    
    echo ""
    echo "Logging in to ghcr.io as ${github_username}..."
    echo "${github_token}" | sudo docker login ghcr.io -u ${github_username} --password-stdin
    
    if [ $? -ne 0 ]; then
        echo "❌ Login failed!"
        exit 1
    fi
    echo "✓ Successfully logged in to GHCR"
else
    echo "✓ Already logged in to GHCR"
fi

echo ""
echo "📦 Tagging image for GHCR..."
sudo docker tag ${LOCAL_IMAGE} ${GHCR_IMAGE}
echo "✓ Tagged: ${GHCR_IMAGE}"

echo ""
echo "⬆️  Pushing to GHCR..."
sudo docker push ${GHCR_IMAGE}

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GHCR!"
    echo ""
    echo "Image URL: ${GHCR_IMAGE}"
    echo ""
    echo "📝 Next steps:"
    echo "1. Make the package public (if needed):"
    echo "   https://github.com/orgs/${GITHUB_ORG}/packages/container/${REPOSITORY_NAME}/settings"
    echo ""
    echo "2. Use this image in Portainer:"
    echo "   Image: ${GHCR_IMAGE}"
    echo ""
else
    echo "❌ Push failed!"
    exit 1
fi
