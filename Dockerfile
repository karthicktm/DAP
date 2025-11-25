# Multi-stage Flutter Web build for Railway deployment
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Create and switch to non-root user for security
RUN useradd -m -s /bin/bash flutteruser

USER flutteruser

# Fix git ownership issue with Flutter SDK for the non-root user
RUN git config --global --add safe.directory /sdks/flutter

# Set working directory
WORKDIR /app

# Copy pubspec files with correct ownership
COPY --chown=flutteruser:flutteruser pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code with correct ownership
COPY --chown=flutteruser:flutteruser . .

# Build web app for production with environment variables support
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
ARG KIE_AI_API_KEY

RUN flutter build web --release --no-web-resources-cdn \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
  --dart-define=KIE_AI_API_KEY=${KIE_AI_API_KEY}

# Production stage with nginx
FROM nginx:stable-alpine

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx configuration for Flutter web
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]