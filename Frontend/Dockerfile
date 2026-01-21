# Multi-stage: build Flutter web, then serve it with nginx.

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

# Ensure web platform exists. If web/ is missing, this will add it.
RUN flutter create --platforms=web .

RUN flutter build web --release

# Copy build artifact into a Deploy-style folder inside the image (matches repo intent)
RUN mkdir -p /Deploy/frontend && cp -R build/web/* /Deploy/frontend/

FROM nginx:stable-alpine
COPY nginx/default.conf /etc/nginx/templates/default.conf.template
COPY --from=build /Deploy/frontend/ /usr/share/nginx/html/
