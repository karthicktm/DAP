const { chromium } = require('playwright');

async function testAudioPlayback() {
  console.log('🎵 Starting Flutter Audio Playback Test...');

  // Connect to the existing Chrome debug session
  const browser = await chromium.connectOverCDP('ws://127.0.0.1:56307/rzEynRrg27Y=/ws');
  const context = browser.contexts()[0];
  const page = context.pages()[0] || await context.newPage();

  try {
    console.log('📱 Connected to Chrome debug session');

    // Wait for the app to load
    await page.waitForTimeout(3000);

    // Take initial screenshot
    await page.screenshot({ path: '01-home-page.png' });
    console.log('📸 Home page screenshot captured');

    // Navigate to AI Music Studio (tab index 1)
    console.log('🎶 Navigating to AI Music Studio...');
    const musicTab = await page.locator('text="AI Music"').first();
    await musicTab.click();
    await page.waitForTimeout(2000);

    // Take screenshot of AI Music Studio
    await page.screenshot({ path: '02-ai-music-studio.png' });
    console.log('📸 AI Music Studio screenshot captured');

    // Navigate to Library tab
    console.log('📚 Navigating to Library tab...');
    const libraryTab = await page.locator('text="Library"').first();
    await libraryTab.click();
    await page.waitForTimeout(2000);

    // Take screenshot of Library
    await page.screenshot({ path: '03-library-tab.png' });
    console.log('📸 Library tab screenshot captured');

    // Wait for track list to load
    await page.waitForTimeout(2000);

    // Look for tracks in the library
    console.log('🔍 Looking for tracks in library...');

    // Try to find track elements
    const tracks = await page.locator('[data-testid="track-tile"], .track-tile, text="Summer Vibes", text="Midnight Jazz", text="Electronic Dreams"').all();
    console.log(`📀 Found ${tracks.length} potential track elements`);

    if (tracks.length > 0) {
      // Take screenshot before playing
      await page.screenshot({ path: '04-tracks-list.png' });
      console.log('📸 Tracks list screenshot captured');

      // Try to click the first play button
      console.log('▶️  Attempting to play first track...');

      // Look for play buttons
      const playButtons = await page.locator('[aria-label*="play"], .play-button, icon="play", text="play_arrow"]').all();

      if (playButtons.length > 0) {
        await playButtons[0].click();
        await page.waitForTimeout(3000);

        // Take screenshot after clicking play
        await page.screenshot({ path: '05-after-play-click.png' });
        console.log('📸 Screenshot after play click captured');

        // Check if mini player appeared
        console.log('🎧 Checking for mini player...');
        const miniPlayer = await page.locator('.mini-player, [class*="mini-player"], text="pause", text="stop"]').first();

        if (await miniPlayer.isVisible()) {
          console.log('✅ Mini player detected!');
          await page.screenshot({ path: '06-mini-player-visible.png' });

          // Test pause/play functionality
          console.log('⏸️  Testing pause functionality...');
          const pauseButton = await miniPlayer.locator('icon="pause", .pause-button, [aria-label*="pause"]').first();
          if (await pauseButton.isVisible()) {
            await pauseButton.click();
            await page.waitForTimeout(2000);
            console.log('✅ Pause button clicked');
            await page.screenshot({ path: '07-after-pause.png' });
          }

          // Test play again
          console.log('▶️  Testing resume functionality...');
          const resumeButton = await miniPlayer.locator('icon="play", .play-button, [aria-label*="play"]').first();
          if (await resumeButton.isVisible()) {
            await resumeButton.click();
            await page.waitForTimeout(2000);
            console.log('✅ Resume button clicked');
            await page.screenshot({ path: '08-after-resume.png' });
          }
        } else {
          console.log('❌ Mini player not found');
        }
      } else {
        console.log('❌ No play buttons found');
      }
    } else {
      console.log('❌ No tracks found in library');

      // Let's try to check what's actually on the page
      const pageContent = await page.content();
      console.log('📄 Page content length:', pageContent.length);

      // Look for any audio-related elements
      const audioElements = await page.locator('audio, [class*="audio"], [data-*="audio"]').all();
      console.log('🔊 Audio elements found:', audioElements.length);

      // Check console for any errors
      page.on('console', (msg) => {
        if (msg.type() === 'error') {
          console.log('❌ Browser console error:', msg.text());
        }
      });

      await page.screenshot({ path: '09-no-tracks-found.png' });
    }

    // Test the other play buttons if they exist
    if (tracks.length > 1) {
      console.log('🎵 Testing multiple tracks...');
      for (let i = 1; i < Math.min(tracks.length, 3); i++) {
        try {
          const trackPlayButton = await tracks[i].locator('icon="play_arrow", .play-button').first();
          if (await trackPlayButton.isVisible()) {
            await trackPlayButton.click();
            await page.waitForTimeout(2000);
            console.log(`✅ Played track ${i + 1}`);
            await page.screenshot({ path: `10-track-${i + 1}-playing.png` });
          }
        } catch (error) {
          console.log(`❌ Error playing track ${i + 1}:`, error.message);
        }
      }
    }

    console.log('🎉 Audio playback test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error);
    await page.screenshot({ path: 'error-screenshot.png' });
  } finally {
    // Don't close the browser since we're connected to an existing session
    console.log('🔌 Test completed, keeping Chrome session active');
  }
}

testAudioPlayback().catch(console.error);