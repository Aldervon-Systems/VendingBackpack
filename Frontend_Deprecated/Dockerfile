FROM nginx:stable-alpine

# Copy Flutter web build
COPY build/web /usr/share/nginx/html
RUN test -f /usr/share/nginx/html/flutter_bootstrap.js

# Copy nginx configuration
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
