# Multi-stage: build Flutter web, then serve it with nginx.

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Force cache break for fresh build
ARG CACHE_DATE=2026-02-01T0650
RUN echo $CACHE_DATE

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Ensure web platform exists BEFORE copying custom web/ assets
RUN flutter create --platforms=web .

COPY . .

RUN flutter build web --release --pwa-strategy=none

# Copy build artifact into a Deploy-style folder inside the image (matches repo intent)
RUN mkdir -p /Deploy/frontend && cp -R build/web/* /Deploy/frontend/

FROM nginx:stable-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /Deploy/frontend/ /usr/share/nginx/html/
