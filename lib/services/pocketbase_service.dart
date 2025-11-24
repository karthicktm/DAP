import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../constants/api_constants.dart';

class PocketBaseService {
  static WebSocketChannel? _chatChannel;
  static WebSocketChannel? _presenceChannel;

  static Future<void> initializeChatConnection() async {
    try {
      _chatChannel = IOWebSocketChannel.connect(
        '${ApiConstants.pocketBaseUrl}/realtime',
      );
    } catch (e) {
      print('Failed to connect to PocketBase chat: $e');
    }
  }

  static Future<void> initializePresenceConnection() async {
    try {
      _presenceChannel = IOWebSocketChannel.connect(
        '${ApiConstants.pocketBaseUrl}/realtime/presence',
      );
    } catch (e) {
      print('Failed to connect to PocketBase presence: $e');
    }
  }

  // Chat functionality
  static void sendMessage({
    required String roomId,
    required String content,
    required String userId,
    String? userName,
    Map<String, dynamic>? metadata,
  }) {
    if (_chatChannel == null) return;

    final message = {
      'type': 'message',
      'roomId': roomId,
      'content': content,
      'userId': userId,
      'userName': userName,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    _chatChannel!.sink.add(jsonEncode(message));
  }

  static void joinRoom(String roomId, String userId) {
    if (_chatChannel == null) return;

    final message = {
      'type': 'join',
      'roomId': roomId,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _chatChannel!.sink.add(jsonEncode(message));
  }

  static void leaveRoom(String roomId, String userId) {
    if (_chatChannel == null) return;

    final message = {
      'type': 'leave',
      'roomId': roomId,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _chatChannel!.sink.add(jsonEncode(message));
  }

  // Real-time presence for live radio
  static void updatePresence({
    required String userId,
    required String stationId,
    String? status,
    Map<String, dynamic>? data,
  }) {
    if (_presenceChannel == null) return;

    final presence = {
      'type': 'presence_update',
      'userId': userId,
      'stationId': stationId,
      'status': status ?? 'listening',
      'timestamp': DateTime.now().toIso8601String(),
      'data': data ?? {},
    };

    _presenceChannel!.sink.add(jsonEncode(presence));
  }

  static void sendGift({
    required String fromUserId,
    required String toUserId,
    required String roomId,
    required String giftType,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) {
    if (_chatChannel == null) return;

    final gift = {
      'type': 'gift',
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'roomId': roomId,
      'giftType': giftType,
      'quantity': quantity ?? 1,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    _chatChannel!.sink.add(jsonEncode(gift));
  }

  static void sendReaction({
    required String roomId,
    required String userId,
    required String reactionType,
    Map<String, dynamic>? metadata,
  }) {
    if (_chatChannel == null) return;

    final reaction = {
      'type': 'reaction',
      'roomId': roomId,
      'userId': userId,
      'reactionType': reactionType,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    _chatChannel!.sink.add(jsonEncode(reaction));
  }

  // Stream subscriptions
  Stream<Map<String, dynamic>>? get chatMessages {
    if (_chatChannel == null) return null;

    return _chatChannel!.stream.map((event) {
      try {
        return jsonDecode(event as String) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing chat message: $e');
        return <String, dynamic>{};
      }
    });
  }

  Stream<Map<String, dynamic>>? get presenceUpdates {
    if (_presenceChannel == null) return null;

    return _presenceChannel!.stream.map((event) {
      try {
        return jsonDecode(event as String) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing presence update: $e');
        return <String, dynamic>{};
      }
    });
  }

  static void dispose() {
    _chatChannel?.sink.close();
    _presenceChannel?.sink.close();
    _chatChannel = null;
    _presenceChannel = null;
  }

  // Utility methods for managing connection state
  static bool get isChatConnected => _chatChannel != null;
  static bool get isPresenceConnected => _presenceChannel != null;

  // Reconnection logic
  static Future<void> reconnect() async {
    await initializeChatConnection();
    await initializePresenceConnection();
  }

  // Heartbeat to keep connection alive
  static void startHeartbeat() {
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (_chatChannel != null) {
        _chatChannel!.sink.add(jsonEncode({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    });
  }
}