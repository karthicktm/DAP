import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class AudioWaveformWidget extends StatefulWidget {
  final AudioService audioService;
  final double height;
  final bool isRecording;
  final Color? waveColor;
  final Color? backgroundColor;

  const AudioWaveformWidget({
    Key? key,
    required this.audioService,
    this.height = 100.0,
    this.isRecording = false,
    this.waveColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget> {
  List<double> _waveformData = [];
  late StreamSubscription _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeWaveform();
    _setupAmplitudeListener();
  }

  void _initializeWaveform() {
    // Initialize with some dummy waveform data
    setState(() {
      _waveformData = List.generate(
        100,
        (index) => (index % 10 == 0 ? 0.8 : 0.2) * (index.isEven ? 1 : -1),
      );
    });
  }

  void _setupAmplitudeListener() {
    _amplitudeSubscription = widget.audioService.recordingAmplitudeStream.listen(
      (amplitude) {
        if (widget.isRecording && mounted) {
          setState(() {
            // Add new amplitude data point
            _waveformData.add(amplitude * (DateTime.now().millisecond % 2 == 0 ? 1 : -1));

            // Keep only the latest 200 points
            if (_waveformData.length > 200) {
              _waveformData.removeAt(0);
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _amplitudeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? const Color(0xFF1A1B3A).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: WaveformPainter(
          waveformData: _waveformData,
          waveColor: widget.waveColor ?? const Color(0xFF8B5CF6),
          isRecording: widget.isRecording,
        ),
        child: Container(),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color waveColor;
  final bool isRecording;

  WaveformPainter({
    required this.waveformData,
    required this.waveColor,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerHeight = size.height / 2;
    final widthPerSample = size.width / waveformData.length;

    // Draw waveform
    final path = Path();

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * widthPerSample;
      final amplitude = waveformData[i].abs();
      final y = centerHeight + (amplitude * centerHeight * 0.8 * (waveformData[i] >= 0 ? -1 : 1));

      if (i == 0) {
        path.moveTo(x, centerHeight);
        path.lineTo(x, y);
      } else {
        final prevX = (i - 1) * widthPerSample;
        final prevAmplitude = waveformData[i - 1].abs();
        final prevY = centerHeight + (prevAmplitude * centerHeight * 0.8 * (waveformData[i - 1] >= 0 ? -1 : 1));

        // Create smooth curve between points
        final controlX = (prevX + x) / 2;
        path.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    // Draw the main waveform line
    canvas.drawPath(path, paint);

    // Add glow effect when recording
    if (isRecording) {
      final glowPaint = Paint()
        ..color = waveColor.withOpacity(0.3)
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawPath(path, glowPaint);
    }

    // Draw center line
    final centerLinePaint = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, centerHeight),
      Offset(size.width, centerHeight),
      centerLinePaint,
    );

    // Draw animated recording indicator
    if (isRecording) {
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final indicatorX = (currentTime * 50) % size.width;

      final indicatorPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(indicatorX, 0),
        Offset(indicatorX, size.height),
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
           oldDelegate.isRecording != isRecording;
  }
}