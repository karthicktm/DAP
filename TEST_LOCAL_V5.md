# 🧪 Local kie.ai v5 Testing Guide

This guide will help you test the kie.ai v5 integration locally with real credentials before deploying.

## 📋 Prerequisites

- Flutter SDK installed
- Dart SDK installed
- Your kie.ai API key
- Your Supabase credentials
- Internet connection for API calls

## 🚀 Testing Steps

### Step 1: Set Up Credentials

Choose one of these methods to provide your credentials:

#### Method A: Environment Variables (Recommended)
```bash
export KIE_AI_API_KEY="your_actual_kie_ai_key"
export SUPABASE_URL="your_supabase_url"
export SUPABASE_ANON_KEY="your_supabase_anon_key"
```

#### Method B: Direct App Configuration
Run this in your Flutter app once:
```dart
await SecureStorageService.setKieAiKey("your_actual_kie_ai_key");
await SecureStorageService.setSupabaseUrl("your_supabase_url");
await SecureStorageService.setSupabaseKey("your_supabase_anon_key");
```

### Step 2: Start Local Webhook Server

Open Terminal 1 and run:
```bash
cd /path/to/your/project
dart test_webhook_local.dart
```

You should see:
```
🚀 Local webhook server running on:
   http://localhost:8080
🔗 Use this webhook URL in your requests:
   http://localhost:8080/api/webhook/music
```

Keep this running - it will show webhook callbacks in real-time.

### Step 3: Test API Connection

Open Terminal 2 and run:
```bash
dart test_local_v5.dart
```

This will:
- ✅ Test Supabase connection
- ✅ Test kie.ai API connection
- ✅ Send a v5 music generation request
- ✅ Show you the taskId

### Step 4: Test Flutter App

Open Terminal 3 and run:
```bash
flutter run
```

Then in the app:
1. Go to AI Music Studio
2. Enable "Show Advanced Options (v5)"
3. Adjust the sliders:
   - Style Weight: 0.75
   - Creativity Level: 0.3
   - Audio Focus: 0.6
4. Set Vocal Gender to "Male" or "Female"
5. Add Exclude Styles: "heavy metal, upbeat drums"
6. Click "Generate Music"

### Step 5: Monitor Real-Time Progress

Watch these outputs:

**Terminal 1 (Webhook Server):**
```
🔔 Webhook callback received
📊 Webhook Summary:
   Status Code: 200
   Callback Type: text
   Task ID: 5c79****be8e

📝 Text generation completed
   Next: Audio generation starting...
```

**Terminal 3 (Flutter App):**
- Progress bar should show "Generating AI Music..."
- After webhook callbacks, status should update
- When complete, audio URL should appear

## 🔍 What to Test

### ✅ v5 Features to Verify

1. **Advanced Parameters Work:**
   - Style Weight affects musical adherence
   - Creativity Level changes experimental elements
   - Audio Focus influences production quality
   - Vocal Gender preference is respected
   - Negative tags exclude unwanted styles

2. **Progress Tracking Works:**
   - Progress bar stops spinning when complete
   - Status updates show: text → first → complete
   - Real-time database updates occur

3. **Data Flow Works:**
   - Supabase gets real track data
   - Audio URLs are accessible
   - Cover art appears if generated

### 🐛 Common Issues & Solutions

**Issue: Webhook not receiving callbacks**
```bash
# Use ngrok for public webhook URL
npm install -g ngrok
ngrok http 8080
# Use the https URL in your test
```

**Issue: Supabase connection fails**
- Check URL format: `https://your-project.supabase.co`
- Verify anon key is correct
- Ensure project is active

**Issue: kie.ai API fails**
- Verify API key format
- Check account has credits
- Confirm v5 model access

**Issue: Progress bar keeps spinning**
- Check webhook server is receiving calls
- Verify Supabase real-time is working
- Check network connectivity

## 📊 Expected Output

### Successful v5 Generation:
```
🎵 Music generation request sent
✅ Task ID: 5c79****be8e

Webhook callbacks received:
1. text → "Text generation completed"
2. first → "First track completed"
3. complete → "All tracks completed!"

Final result:
- Title: "Test V5 Generation"
- Audio URL: https://example.com/audio.mp3
- Duration: 180s
- Model: V5
- v5 params applied successfully
```

## 🎯 Success Criteria

- [ ] All 3 webhook callbacks received (text, first, complete)
- [ ] v5 parameters visible in generation request
- [ ] Progress bar stops spinning after completion
- [ ] Audio URL is accessible and plays
- [ ] Supabase database contains track record
- [ ] Real-time updates work in UI
- [ ] No errors in any terminal windows

## 🆘 Getting Help

If you encounter issues:

1. **Check logs in all 3 terminals**
2. **Verify credentials are correct**
3. **Test with simpler parameters first**
4. **Check network connectivity**
5. **Verify kie.ai account has credits**

## 🚀 Ready for Deployment?

Once local testing passes:
- Update Railway webhook URL in production
- Deploy webhook server to Railway
- Test with production webhook URL
- Monitor production logs for issues

---

**Note:** Replace all placeholder URLs and keys with your actual credentials before testing.