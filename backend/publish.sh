#!/usr/bin/env bash
set -euo pipefail

# Usage: ./publish.sh [tag]
# Example: ./publish.sh v2025.11.27

TAG=${1:-latest}
IMAGE="simonswartout/aldervon-vending-backend:${TAG}"

echo "Building ${IMAGE} from ./backend"
docker build -t "${IMAGE}" ./backend

echo "Pushing ${IMAGE}"
docker push "${IMAGE}"

if [ "${TAG}" != "latest" ]; then
  echo "Also tagging and pushing :latest"
  docker tag "${IMAGE}" simonswartout/aldervon-vending-backend:latest
  docker push simonswartout/aldervon-vending-backend:latest
fi

echo "Publish complete: ${IMAGE}"
