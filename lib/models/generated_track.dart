/// Generated track data model (moved from ai_music_service.dart for better organization)
class GeneratedTrack {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String mood;
  final String audioUrl;
  final String coverImageUrl;
  final int duration;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const GeneratedTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.mood,
    required this.audioUrl,
    required this.coverImageUrl,
    required this.duration,
    required this.createdAt,
    this.metadata = const {},
  });

  factory GeneratedTrack.fromJson(Map<String, dynamic> json) {
    return GeneratedTrack(
      id: json['id'] ?? json['taskId'] ?? '',
      title: json['title'] ?? 'Generated Track',
      artist: json['artist'] ?? 'AI Artist',
      genre: json['genre'] ?? 'pop',
      mood: json['mood'] ?? 'happy',
      audioUrl: json['audio_url'] ?? json['audioUrl'] ?? '',
      coverImageUrl: json['cover_image_url'] ?? json['coverImageUrl'] ?? '',
      duration: json['duration'] ?? 120,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'genre': genre,
      'mood': mood,
      'audio_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}