// Test script to debug webhook flow and simulate kie.ai callbacks
import 'dart:convert';
import 'dart:io';

void main() async {
  await testWebhookFlow();
}

Future<void> testWebhookFlow() async {
  final baseUrl = 'https://dap-production-99ef.up.railway.app';

  print('🔍 Testing webhook debugging flow...\n');

  // 1. Check webhook status
  await checkWebhookStatus(baseUrl);

  // 2. Simulate kie.ai "first" callback
  await simulateKieAiCallback(baseUrl, 'first');

  // 3. Simulate kie.ai "complete" callback
  await simulateKieAiCallback(baseUrl, 'complete');

  print('\n✅ Webhook debugging test completed!');
}

Future<void> checkWebhookStatus(String baseUrl) async {
  try {
    print('📊 Checking webhook status...');

    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$baseUrl/api/webhook/status'));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('Status: ${response.statusCode}');
    print('Response: $responseBody\n');

    client.close();
  } catch (e) {
    print('❌ Error checking status: $e\n');
  }
}

Future<void> simulateKieAiCallback(String baseUrl, String callbackType) async {
  try {
    print('🎵 Simulating kie.ai "$callbackType" callback...');

    final taskId = 'debug_test_${DateTime.now().millisecondsSinceEpoch}';

    Map<String, dynamic> payload;

    if (callbackType == 'first') {
      payload = {
        'code': 200,
        'msg': 'success',
        'data': {
          'callbackType': 'first',
          'task_id': taskId,
          'data': [
            {
              'id': 'track_${taskId}_1',
              'title': 'Debug Test Track (First)',
              'audio_url': 'https://example.com/debug_first.mp3',
              'duration': 120,
              'prompt': 'Debug test track for webhook flow'
            }
          ]
        }
      };
    } else {
      payload = {
        'code': 200,
        'msg': 'success',
        'data': {
          'callbackType': 'complete',
          'task_id': taskId,
          'data': [
            {
              'id': 'track_${taskId}_final',
              'title': 'Debug Test Track (Complete)',
              'audio_url': 'https://example.com/debug_complete.mp3',
              'image_url': 'https://example.com/debug_cover.jpg',
              'duration': 180,
              'prompt': 'Debug test track for webhook flow',
              'model_name': 'V5',
              'tags': 'debug, test, webhook'
            }
          ]
        }
      };
    }

    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$baseUrl/api/webhook/music'));
    request.headers.set('Content-Type', 'application/json');

    final jsonPayload = jsonEncode(payload);
    request.write(jsonPayload);

    print('📤 Sending payload: ${jsonPayload.substring(0, 100)}...');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('📥 Response: ${response.statusCode}');
    print('📄 Body: $responseBody');

    if (response.statusCode == 200) {
      print('✅ $callbackType callback successful');
    } else {
      print('❌ $callbackType callback failed');
    }

    client.close();

    // Wait a bit between callbacks
    await Future.delayed(Duration(seconds: 2));
    print('');

  } catch (e) {
    print('❌ Error simulating $callbackType callback: $e\n');
  }
}

// Additional debugging utilities
class WebhookDebugger {
  static void printTaskIdFlow(String taskId) {
    print('''
🔍 Debugging Task ID Flow:
1. taskId created: $taskId
2. Track saved with is_processing: true
3. Webhook should arrive at: /api/webhook/music
4. Webhook should update track with real audio_url
5. Track should show is_processing: false

Expected webhook payload structure:
{
  "code": 200,
  "data": {
    "callbackType": "complete",
    "task_id": "$taskId",
    "data": [{
      "audio_url": "real_url_here",
      "title": "track_title"
    }]
  }
}
''');
  }

  static void printCommonIssues() {
    print('''
🚨 Common Webhook Issues:

1. Callback URL wrong or unreachable
2. kie.ai not sending callbacks (check their logs)
3. Database schema missing columns
4. Webhook server not parsing payload correctly
5. Track not found in database (wrong taskId)
6. CORS issues preventing callbacks

Check Railway logs for webhook server output!
''');
  }
}