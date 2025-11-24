# Railway Deployment Guide

## 🚀 Deploy Your AI Music App to Railway

This guide will help you deploy your Flutter AI music generation app to Railway.com with proper webhook support.

## Prerequisites

1. Railway.com account
2. GitHub repository with your code
3. kie.ai API key

## 📋 Step-by-Step Deployment

### 1. Prepare Your Repository

Ensure these files are in your project root:
- ✅ `Dockerfile` (created)
- ✅ `railway.toml` (created)
- ✅ `nginx.conf` (created)

### 2. Deploy to Railway

#### Option A: GitHub Integration (Recommended)
1. Go to [Railway.app](https://railway.app)
2. Click "Deploy from GitHub repo"
3. Connect your GitHub account
4. Select your repository
5. Railway will auto-detect the Dockerfile and deploy

#### Option B: Railway CLI
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Initialize project
railway init

# Deploy
railway up
```

### 3. Configure Environment Variables

In Railway dashboard → Your Project → Variables:

```bash
# Required for kie.ai API
KIE_AI_API_KEY=your_actual_kie_ai_api_key_here

# Flutter Environment
FLUTTER_ENV=production
DEBUG_MODE=false

# Railway will auto-set these:
RAILWAY_STATIC_URL=your-app-name.railway.app
PORT=80
```

### 4. Get Your Deployment URL

After deployment, Railway provides:
- **Public URL**: `https://your-app-name.railway.app`
- **Webhook URL**: `https://your-app-name.railway.app/api/webhook/music`

### 5. Verify Webhook Integration

The app now uses dynamic webhook URLs:
```dart
// Before (hardcoded)
'callBackUrl': 'https://your-app-callback.com/webhook'

// After (dynamic)
'callBackUrl': WebhookService.getWebhookUrl()
```

## 🔧 Key Features Fixed

### ✅ Webhook URL Resolution
- Automatically detects Railway deployment URL
- Uses `RAILWAY_STATIC_URL` environment variable
- Falls back gracefully for local development

### ✅ Proper nginx Configuration
- Handles Flutter web routing
- Serves static assets efficiently
- Includes health check endpoint

### ✅ Production-Ready Build
- Multi-stage Docker build
- Optimized Flutter web build
- Compressed asset delivery

## 🎯 Testing Your Deployment

### 1. Check App Health
```bash
curl https://your-app-name.railway.app/health
# Should return: "healthy"
```

### 2. Test AI Music Generation
1. Open your deployed app
2. Navigate to music generation
3. Create a track with your kie.ai API key
4. Webhooks should now work properly!

### 3. Monitor Logs
In Railway dashboard → Deployments → View Logs

## 🐛 Troubleshooting

### Build Failures
- Check Flutter version compatibility
- Ensure `pubspec.yaml` dependencies are valid
- Verify Dockerfile syntax

### Webhook Issues
- Confirm `RAILWAY_STATIC_URL` is set correctly
- Check kie.ai API key is valid
- Monitor Railway logs for webhook calls

### App Not Loading
- Check nginx configuration
- Verify build completed successfully
- Check for Flutter web build errors

## 🚀 Next Steps

### Add Custom Domain (Optional)
1. Railway dashboard → Settings → Domains
2. Add your custom domain
3. Update `CUSTOM_DOMAIN` environment variable

### Enable HTTPS (Auto-configured)
Railway automatically provides SSL certificates for all deployments.

### Scale Resources
Railway automatically scales based on usage. You can configure limits in the dashboard.

## 📊 Monitoring

- **Logs**: Railway dashboard → Deployments → Logs
- **Metrics**: Railway dashboard → Metrics tab
- **Health**: `https://your-app.railway.app/health`

## 🎉 Success!

Your AI music app is now deployed with:
- ✅ Working webhooks from kie.ai
- ✅ Production-ready Flutter web app
- ✅ Automatic SSL and scaling
- ✅ Health monitoring

Access your app at: `https://your-app-name.railway.app`

---

**👨 Daddy says:** Test your deployed app with a real music generation request - make sure those kie.ai credits aren't going to waste!