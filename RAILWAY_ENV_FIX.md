# Railway Environment Variables Fix 🚀

## Problem
Users accessing the web app hosted on Railway were being asked to setup API keys manually, even after setting environment variables in the Railway dashboard.

## Root Cause
Flutter web apps don't automatically read Railway environment variables at runtime. The `String.fromEnvironment()` calls in `api_constants.dart` only work at **compile time** when passed as `--dart-define` flags.

## Solution Applied ✅

### 1. Updated Settings Provider
- **File**: `lib/providers/settings_provider.dart`
- **Change**: Modified `_loadSettings()` to check environment variables as fallback when local storage is empty
- **Logic**: Storage first → Environment variables second → Show setup screen only if both are empty

### 2. Environment Variable Fallback Chain
```dart
// 1. Try local storage first (user manually entered keys)
var kieAiKey = await SecureStorageService.getKieAiKey();

// 2. Fallback to environment variables from Railway
kieAiKey ??= ApiConstants.kieAiApiKey != 'your_kie_ai_api_key_here'
    ? ApiConstants.kieAiApiKey : null;
```

### 3. Railway Deployment Configuration
- **Files**: `railway.toml` and `Dockerfile.railway`
- **Purpose**: Ensures environment variables are passed as `--dart-define` flags during build
- **Approach**: Custom Dockerfile with proper Flutter setup and non-root user
- **Command**:
```bash
flutter build web \
  --dart-define=KIE_AI_API_KEY=$KIE_AI_API_KEY \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --release
```
- **Fixes Applied**:
  - ✅ Removed deprecated `--web-renderer` flag
  - ✅ Created non-root user to avoid Flutter root warnings
  - ✅ Proper working directory setup to find pubspec.yaml
  - ✅ Custom Dockerfile for reliable Flutter builds

### 4. Build Script
- **File**: `build_for_railway.sh`
- **Purpose**: Manual build script for testing Railway deployment locally

## How to Deploy on Railway

### Step 1: Set Environment Variables in Railway Dashboard
```
KIE_AI_API_KEY = your_actual_kie_ai_api_key
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your_actual_supabase_anon_key
```

### Step 2: Deploy with Railway.toml
The `railway.toml` file automatically handles the build process with proper environment variable injection.

### Step 3: Verify Deployment
1. Open the Railway app URL
2. Environment variables should be automatically loaded
3. No manual setup screen should appear for users
4. Music generation should work immediately

## Technical Details

### Before Fix
```
User opens app → Only checks local storage → Storage empty → Shows setup screen ❌
```

### After Fix
```
User opens app → Checks storage → Storage empty → Checks env vars → Found → Ready to use ✅
```

### Services Updated
- ✅ `AIMusicService` - Already had fallback logic
- ✅ `TrackDatabaseService` - Already had fallback logic
- ✅ `SettingsProvider` - Updated with fallback logic

## Testing
1. **Local**: Use `build_for_railway.sh` with test environment variables
2. **Railway**: Deploy and verify no setup screen appears
3. **Functionality**: Test music generation works immediately

## Notes
- User manually entered keys still take priority over environment variables
- Environment variables are only used as fallback when storage is empty
- This maintains security while providing convenience for shared deployments