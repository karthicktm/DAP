import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // Authentication methods
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
      },
    );
    return response;
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  // Database methods
  static Future<List<Map<String, dynamic>>> fetchStations() async {
    final response = await client
        .from('stations')
        .select('*')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<List<Map<String, dynamic>>> fetchUserTracks() async {
    if (currentUser == null) return [];

    final response = await client
        .from('ai_tracks')
        .select('*')
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<Map<String, dynamic>> saveTrack({
    required String title,
    required String audioUrl,
    required String coverImageUrl,
    required String genre,
    required String mood,
    int? duration,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final trackData = {
      'user_id': currentUser!.id,
      'title': title,
      'audio_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'genre': genre,
      'mood': mood,
      'duration': duration,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('ai_tracks')
        .insert(trackData)
        .select()
        .single();
    return response;
  }

  // Real-time subscriptions
  static Stream<List<Map<String, dynamic>>> streamStations() {
    return client
        .from('stations')
        .stream(primaryKey: ['id'])
        .eq('is_active', true);
  }

  static Stream<List<Map<String, dynamic>>> streamUserTracks() {
    if (currentUser == null) return Stream.value([]);

    return client
        .from('ai_tracks')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser!.id);
  }

  // Storage methods
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    final response = await client.storage
        .from(bucket)
        .uploadBinary(path, fileBytes, fileOptions: FileOptions(contentType: contentType));

    return response;
  }

  static Future<String> getPublicUrl({
    required String bucket,
    required String path,
  }) async {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  // User profile methods
  static Future<Map<String, dynamic>> updateUserProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (displayName != null) updateData['display_name'] = displayName;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (bio != null) updateData['bio'] = bio;
    if (preferences != null) updateData['preferences'] = preferences;

    final response = await client
        .from('user_profiles')
        .update(updateData)
        .eq('user_id', currentUser!.id)
        .select()
        .single();
    return response;
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await client
        .from('user_profiles')
        .select('*')
        .eq('user_id', userId)
        .single();
    return response;
  }

  // Analytics and usage tracking
  static Future<void> trackEvent({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    if (currentUser == null) return;

    await client.from('analytics_events').insert({
      'user_id': currentUser!.id,
      'event_name': eventName,
      'properties': properties,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Chat and real-time features
  static Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
    String? messageType,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final messageData = {
      'room_id': roomId,
      'user_id': currentUser!.id,
      'content': content,
      'message_type': messageType ?? 'text',
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('chat_messages')
        .insert(messageData)
        .select()
        .single();
    return response;
  }

  static Stream<List<Map<String, dynamic>>> streamChatMessages(String roomId) {
    return client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
  }
}