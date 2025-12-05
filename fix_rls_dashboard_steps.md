# Fix RLS Policies in Supabase Dashboard

## Step 1: Go to Bucket Settings
1. Open: https://supabase.com/dashboard/project/bgoasjlsfgaztmvdofvq/storage
2. Click on the `voice_recordings` bucket
3. Click "Settings" tab

## Step 2: Create RLS Policies
1. In the bucket Settings, click "Policies" section
2. Click "New Policy" button
3. Select "For full customization"
4. Choose policy name: `Allow all operations for testing`
5. Policy definition:
   ```sql
   -- Allow all operations on voice_recordings bucket
   bucket_id = 'voice_recordings'
   ```
6. Set Policy to: "Allow all operations"
7. Policy Target: "All roles"
8. Click "Save"

## Step 3: Alternative - Enable Public Access
1. In bucket Settings, make sure "Public bucket" is checked
2. This bypasses RLS for read operations
3. You still need policies for write operations

## Step 4: Test After Fixing
Once policies are set, the API should return 200 instead of 403 errors.