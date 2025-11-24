# Multi-stage Flutter Web build for Railway deployment
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Create non-root user for Flutter
RUN useradd -m -u 1000 flutter
USER flutter
WORKDIR /home/flutter/app

# Copy pubspec files with correct ownership
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code with correct ownership
COPY --chown=flutter:flutter . .

# Build web app for production
RUN flutter build web --release --no-web-resources-cdn

# Production stage with nginx
FROM nginx:stable-alpine

# Copy built web app
COPY --from=builder /home/flutter/app/build/web /usr/share/nginx/html

# Copy nginx configuration for Flutter web
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]