import 'package:flutter/material.dart';
import '../services/ai_music_service.dart';
import '../models/ai_track.dart';
import '../utils/logger.dart';
import 'glassmorphic_card.dart';

class MusicGenerationForm extends StatefulWidget {
  final AIMusicService aiMusicService;
  final VoidCallback onGenerationStart;
  final Function(AITrack track) onGenerationComplete;
  final Function(String error) onGenerationError;

  const MusicGenerationForm({
    Key? key,
    required this.aiMusicService,
    required this.onGenerationStart,
    required this.onGenerationComplete,
    required this.onGenerationError,
  }) : super(key: key);

  @override
  State<MusicGenerationForm> createState() => _MusicGenerationFormState();
}

class _MusicGenerationFormState extends State<MusicGenerationForm> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _lyricsController = TextEditingController();

  String _selectedGenre = 'Pop';
  String _selectedMood = 'Energetic';
  String _selectedStyle = 'Modern';
  double _duration = 60;
  bool _includeVocals = true;
  bool _generateLyrics = false;
  bool _isArabicMode = false;
  bool _showAdvancedOptions = false;
  String? _currentTaskId; // Store current generation taskId

  // v5 Advanced Parameters
  double _styleWeight = 0.65;
  double _weirdnessConstraint = 0.5;
  double _audioWeight = 0.5;
  String _negativeTags = '';
  String _vocalGender = '';

  @override
  void dispose() {
    _promptController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Music Description', Icons.description),
              const SizedBox(height: 12),
              TextFormField(
                controller: _promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Describe your music',
                  hintText: 'e.g., Upbeat electronic music with modern production',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF252641).withOpacity(0.5),
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your music';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _buildSectionHeader('Style & Genre', Icons.style),
              const SizedBox(height: 12),

              // Genre Selection
              Text(
                'Genre',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getGenreList().map((genre) => ChoiceChip(
                  label: Text(genre),
                  selected: _selectedGenre == genre,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedGenre = genre);
                  },
                  backgroundColor: const Color(0xFF252641),
                  selectedColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: _selectedGenre == genre ? const Color(0xFF8B5CF6) : Colors.white70,
                  ),
                  side: BorderSide(
                    color: _selectedGenre == genre
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF8B5CF6).withOpacity(0.3),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 16),

              // Mood Selection
              Text(
                'Mood',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Energetic', 'Relaxing', 'Happy', 'Sad', 'Mysterious',
                  'Dramatic', 'Romantic', 'Dark', 'Bright', 'Calm'
                ].map((mood) => ChoiceChip(
                  label: Text(mood),
                  selected: _selectedMood == mood,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMood = mood);
                  },
                  backgroundColor: const Color(0xFF252641),
                  selectedColor: const Color(0xFFEC4899).withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: _selectedMood == mood ? const Color(0xFFEC4899) : Colors.white70,
                  ),
                  side: BorderSide(
                    color: _selectedMood == mood
                      ? const Color(0xFFEC4899)
                      : const Color(0xFFEC4899).withOpacity(0.3),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 16),

              // Style Selection
              Text(
                'Production Style',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Modern', 'Vintage', 'Minimalist', 'Orchestral',
                  'Lo-fi', 'Electronic', 'Acoustic'
                ].map((style) => ChoiceChip(
                  label: Text(style),
                  selected: _selectedStyle == style,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStyle = style);
                  },
                  backgroundColor: const Color(0xFF252641),
                  selectedColor: const Color(0xFF14B8A6).withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: _selectedStyle == style ? const Color(0xFF14B8A6) : Colors.white70,
                  ),
                  side: BorderSide(
                    color: _selectedStyle == style
                      ? const Color(0xFF14B8A6)
                      : const Color(0xFF14B8A6).withOpacity(0.3),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 20),

              _buildSectionHeader('Audio Settings', Icons.settings),
              const SizedBox(height: 12),

              // Duration Slider
              Row(
                children: [
                  Text(
                    'Duration: ${_duration.round()}s',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_duration / 60).toStringAsFixed(1)} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF8B5CF6),
                  inactiveTrackColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                  thumbColor: const Color(0xFF8B5CF6),
                  overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _duration,
                  min: 15,
                  max: 300,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() => _duration = value);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Option Toggles
              _buildOptionToggle('Include Vocals', _includeVocals, (value) {
                setState(() => _includeVocals = value);
              }),

              _buildOptionToggle('Generate Lyrics', _generateLyrics, (value) {
                setState(() => _generateLyrics = value);
              }),

              _buildOptionToggle('Arabic Music Mode', _isArabicMode, (value) {
                setState(() {
                  _isArabicMode = value;
                  // Reset genre selection when switching modes
                  if (_isArabicMode) {
                    _selectedGenre = 'Arabic Traditional';
                  } else {
                    _selectedGenre = 'Pop';
                  }
                });
              }),

              if (_generateLyrics) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lyricsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Custom Lyrics (Optional)',
                    hintText: 'Enter your lyrics or leave empty to generate automatically',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252641).withOpacity(0.5),
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ],

              const SizedBox(height: 20),

              // Advanced Options Toggle
              _buildOptionToggle('Show Advanced Options (v5)', _showAdvancedOptions, (value) {
                setState(() => _showAdvancedOptions = value);
              }),

              // Advanced v5 Options
              if (_showAdvancedOptions) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('Advanced v5 Options', Icons.tune),
                const SizedBox(height: 12),

                // Style Weight
                _buildSliderOption(
                  'Style Weight',
                  'How strongly to follow the style specification',
                  _styleWeight,
                  (value) => setState(() => _styleWeight = value),
                ),

                // Weirdness Constraint
                _buildSliderOption(
                  'Creativity Level',
                  'Controls experimental and creative deviation',
                  _weirdnessConstraint,
                  (value) => setState(() => _weirdnessConstraint = value),
                ),

                // Audio Weight
                _buildSliderOption(
                  'Audio Focus',
                  'Balance weight for audio features vs other factors',
                  _audioWeight,
                  (value) => setState(() => _audioWeight = value),
                ),

                const SizedBox(height: 12),

                // Vocal Gender Selection
                Text(
                  'Vocal Gender (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text('Any'),
                      selected: _vocalGender == '',
                      onSelected: (selected) {
                        if (selected) setState(() => _vocalGender = '');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Male'),
                      selected: _vocalGender == 'm',
                      onSelected: (selected) {
                        if (selected) setState(() => _vocalGender = 'm');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Female'),
                      selected: _vocalGender == 'f',
                      onSelected: (selected) {
                        if (selected) setState(() => _vocalGender = 'f');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Negative Tags
                TextFormField(
                  initialValue: _negativeTags,
                  decoration: InputDecoration(
                    labelText: 'Exclude Styles (Optional)',
                    hintText: 'e.g., Heavy Metal, Upbeat Drums',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252641).withOpacity(0.5),
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) => _negativeTags = value,
                ),
              ],

              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _generateMusic,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Generate Music',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getGenreList() {
    if (_isArabicMode) {
      return [
        'Arabic Traditional', 'Arabic Pop', 'Arabic Classical', 'Maqam',
        'Tarab', 'Dabke', 'Khaleeji', 'Maghrebi', 'Andalusi', 'Sufi'
      ];
    } else {
      return [
        'Pop', 'Electronic', 'Rock', 'Jazz', 'Classical', 'Hip Hop',
        'R&B', 'Country', 'Folk', 'Reggae', 'Blues', 'Metal'
      ];
    }
  }

  String _mapGenreToApiFormat(String displayGenre) {
    // Map UI display names to API format
    const genreMapping = {
      'Arabic Traditional': 'arabic_traditional',
      'Arabic Pop': 'arabic_pop',
      'Arabic Classical': 'arabic_classical',
      'Hip Hop': 'hip_hop',
      'R&B': 'r&b',
    };

    return genreMapping[displayGenre] ?? displayGenre.toLowerCase();
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionToggle(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF8B5CF6),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderOption(String title, String description, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: const Color(0xFF8B5CF6).withOpacity(0.3),
              thumbColor: const Color(0xFF8B5CF6),
              overlayColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMusic() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onGenerationStart();

    try {
      final generatedTrack = await widget.aiMusicService.generateMusic(
        prompt: _promptController.text.trim(),
        genre: _mapGenreToApiFormat(_selectedGenre),
        mood: _selectedMood.toLowerCase(),
        style: _selectedStyle.toLowerCase(),
        duration: _duration.round(),
        includeLyrics: _generateLyrics,
        lyrics: _generateLyrics && _lyricsController.text.isNotEmpty
          ? _lyricsController.text.trim()
          : null,
        instrumental: !_includeVocals,
        language: _isArabicMode ? 'arabic' : 'english',
        model: 'V5',
        // v5 Advanced Parameters
        styleWeight: _showAdvancedOptions ? _styleWeight : null,
        weirdnessConstraint: _showAdvancedOptions ? _weirdnessConstraint : null,
        audioWeight: _showAdvancedOptions ? _audioWeight : null,
        vocalGender: _showAdvancedOptions && _vocalGender.isNotEmpty ? _vocalGender : null,
        negativeTags: _showAdvancedOptions && _negativeTags.isNotEmpty ? _negativeTags : null,
      );

      // Webhook-based system: processing track is already saved to database
      // Real track will be updated via webhook when AI service completes generation
      Logger.log('🎵 Music generation submitted successfully via webhook system');
    } catch (e) {
      // Create error track with same parameters as would have been used for processing
      final errorTrack = AITrack(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        title: _promptController.text.trim().length > 50
            ? '${_promptController.text.trim().substring(0, 47)}...'
            : _promptController.text.trim(),
        artist: 'AI Artist',
        genre: _selectedGenre,
        mood: _selectedMood,
        duration: Duration(seconds: _duration.round()),
        audioUrl: '',
        createdAt: DateTime.now(),
        isInstrumental: !_includeVocals,
        lyrics: _generateLyrics && _lyricsController.text.isNotEmpty
            ? _lyricsController.text.trim()
            : null,
        isProcessing: false,
        processingStatus: 'Generation failed',
        processingCompleted: false,
      );
      widget.onGenerationComplete(errorTrack);
      widget.onGenerationError(e.toString());
    }
  }
}