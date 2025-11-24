class AITrack {
  final String id;
  final String title;
  final String artist;
  final String genre;
  final String mood;
  final Duration duration;
  final String audioUrl;
  final String? coverArtUrl;
  final DateTime createdAt;
  final bool isInstrumental;
  final String? lyrics;
  final Map<String, dynamic>? metadata;
  final bool isProcessing;
  final String? processingStatus;
  final bool processingCompleted;

  const AITrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.mood,
    required this.duration,
    required this.audioUrl,
    this.coverArtUrl,
    required this.createdAt,
    this.isInstrumental = false,
    this.lyrics,
    this.metadata,
    this.isProcessing = false,
    this.processingStatus,
    this.processingCompleted = false,
  });

  factory AITrack.fromJson(Map<String, dynamic> json) {
    return AITrack(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      genre: json['genre'] as String,
      mood: json['mood'] as String,
      duration: Duration(
        minutes: json['duration_minutes'] ?? 0,
        seconds: json['duration_seconds'] ?? json['duration'] ?? 0,
      ),
      audioUrl: json['audio_url'] as String? ?? json['audioUrl'] as String? ?? '',
      coverArtUrl: json['cover_art_url'] as String? ?? json['coverArtUrl'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
      isInstrumental: json['is_instrumental'] as bool? ?? json['isInstrumental'] as bool? ?? false,
      lyrics: json['lyrics'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isProcessing: json['isProcessing'] as bool? ?? false,
      processingStatus: json['processingStatus'] as String?,
      processingCompleted: json['processingCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'genre': genre,
      'mood': mood,
      'duration_minutes': duration.inMinutes,
      'duration_seconds': duration.inSeconds % 60,
      'audio_url': audioUrl,
      'cover_art_url': coverArtUrl,
      'created_at': createdAt.toIso8601String(),
      'is_instrumental': isInstrumental,
      'lyrics': lyrics,
      'metadata': metadata,
      'isProcessing': isProcessing,
      'processingStatus': processingStatus,
      'processingCompleted': processingCompleted,
    };
  }

  AITrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? genre,
    String? mood,
    Duration? duration,
    String? audioUrl,
    String? coverArtUrl,
    DateTime? createdAt,
    bool? isInstrumental,
    String? lyrics,
    Map<String, dynamic>? metadata,
    bool? isProcessing,
    String? processingStatus,
    bool? processingCompleted,
  }) {
    return AITrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      mood: mood ?? this.mood,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      createdAt: createdAt ?? this.createdAt,
      isInstrumental: isInstrumental ?? this.isInstrumental,
      lyrics: lyrics ?? this.lyrics,
      metadata: metadata ?? this.metadata,
      isProcessing: isProcessing ?? this.isProcessing,
      processingStatus: processingStatus ?? this.processingStatus,
      processingCompleted: processingCompleted ?? this.processingCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AITrack && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AITrack(id: $id, title: $title, artist: $artist, genre: $genre, mood: $mood)';
  }
}