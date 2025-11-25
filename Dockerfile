# Multi-stage build: Flutter Web + Dart Webhook Server
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Create a non-root user and give necessary permissions
RUN adduser --disabled-password --gecos '' flutteruser && \
    chown -R flutteruser:flutteruser /sdks/flutter && \
    chmod -R 755 /sdks/flutter

USER flutteruser

# Set working directory
WORKDIR /app

# Copy pubspec files with proper ownership
COPY --chown=flutteruser:flutteruser pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code with proper ownership
COPY --chown=flutteruser:flutteruser . .

# Build web app for production with environment variables support
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
ARG KIE_AI_API_KEY

RUN flutter build web --release --no-web-resources-cdn \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
  --dart-define=KIE_AI_API_KEY=${KIE_AI_API_KEY}

# Build webhook server executable
RUN dart compile exe bin/webhook_server.dart -o webhook_server

# Production stage with Dart runtime for webhook server
FROM ghcr.io/cirruslabs/flutter:stable

# Install nginx for serving Flutter web
RUN apt-get update && \
    apt-get install -y nginx supervisor && \
    rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy built web app to nginx directory
COPY --from=builder /app/build/web /var/www/html

# Copy webhook server executable
COPY --from=builder /app/webhook_server /app/webhook_server

# Copy nginx configuration
COPY nginx.conf /etc/nginx/sites-available/default

# Create supervisor configuration to run both nginx and webhook server
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:nginx]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=nginx -g "daemon off;"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/dev/stdout' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/dev/stderr' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:webhook_server]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/app/webhook_server' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/dev/stdout' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/dev/stderr' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]