import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Modern audio visualizer with animated bars
class AudioVisualizer extends StatefulWidget {
  final List<double> audioData;
  final Color? color;
  final double? width;
  final double? height;
  final int barCount;
  final double barSpacing;
  final bool isAnimating;
  final Duration animationDuration;

  const AudioVisualizer({
    Key? key,
    required this.audioData,
    this.color,
    this.width,
    this.height,
    this.barCount = 30,
    this.barSpacing = 2.0,
    this.isAnimating = true,
    this.animationDuration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<double> _currentHeights;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioData != widget.audioData) {
      _updateAnimations();
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.1,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOutCubic,
            )))
        .toList();

    _currentHeights = List.filled(widget.barCount, 0.1);
    _updateAnimations();
  }

  void _updateAnimations() {
    final audioData = widget.audioData.isEmpty
        ? List.filled(widget.barCount, Random().nextDouble())
        : _normalizeAudioData();

    for (int i = 0; i < widget.barCount; i++) {
      if (i < audioData.length) {
        _currentHeights[i] = audioData[i];
      }

      if (widget.isAnimating) {
        _controllers[i].forward().then((_) {
          _controllers[i].reverse();
        });
      }
    }
  }

  List<double> _normalizeAudioData() {
    if (widget.audioData.isEmpty) return [];

    final maxValue = widget.audioData.reduce((a, b) => a > b ? a : b);
    final normalizedData = widget.audioData.map((value) {
      return maxValue > 0 ? (value / maxValue).clamp(0.1, 1.0) : 0.1;
    }).toList();

    // Interpolate to match bar count
    if (normalizedData.length != widget.barCount) {
      return _interpolateData(normalizedData, widget.barCount);
    }

    return normalizedData;
  }

  List<double> _interpolateData(List<double> data, int targetLength) {
    if (data.isEmpty) return List.filled(targetLength, 0.1);

    final result = <double>[];
    final step = (data.length - 1) / (targetLength - 1);

    for (int i = 0; i < targetLength; i++) {
      final index = (i * step).floor();
      final fraction = (i * step) - index;

      if (index >= data.length - 1) {
        result.add(data.last);
      } else {
        result.add(
          data[index] * (1 - fraction) + data[index + 1] * fraction,
        );
      }
    }

    return result;
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height ?? 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return _buildBar(index);
        }),
      ),
    );
  }

  Widget _buildBar(int index) {
    final baseHeight = _currentHeights[index];

    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        final animatedHeight = widget.isAnimating
            ? baseHeight * _animations[index].value
            : baseHeight;

        return Container(
          width: (widget.width ?? 200) / widget.barCount - widget.barSpacing,
          height: animatedHeight * (widget.height ?? 60),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getBarGradientColors(index),
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: animatedHeight > 0.5 ? [
              BoxShadow(
                color: (widget.color ?? AppColors.audioWavePrimary).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ] : null,
          ),
        );
      },
    );
  }

  List<Color> _getBarGradientColors(int index) {
    final baseColor = widget.color ?? AppColors.audioWavePrimary;

    // Create gradient based on position
    if (index < widget.barCount / 3) {
      return [
        baseColor,
        baseColor.withOpacity(0.8),
      ];
    } else if (index < 2 * widget.barCount / 3) {
      return [
        AppColors.audioWaveSecondary,
        AppColors.audioWaveSecondary.withOpacity(0.8),
      ];
    } else {
      return [
        AppColors.audioWaveAccent,
        AppColors.audioWaveAccent.withOpacity(0.8),
      ];
    }
  }
}

/// Circular audio visualizer (radial bars)
class CircularAudioVisualizer extends StatefulWidget {
  final List<double> audioData;
  final Color? color;
  final double? radius;
  final double strokeWidth;
  final int barCount;
  final bool isAnimating;

  const CircularAudioVisualizer({
    Key? key,
    required this.audioData,
    this.color,
    this.radius,
    this.strokeWidth = 4.0,
    this.barCount = 60,
    this.isAnimating = true,
  }) : super(key: key);

  @override
  State<CircularAudioVisualizer> createState() => _CircularAudioVisualizerState();
}

class _CircularAudioVisualizerState extends State<CircularAudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    if (widget.isAnimating) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? 40;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * pi,
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: CustomPaint(
              painter: _CircularVisualizerPainter(
                audioData: widget.audioData,
                color: widget.color ?? AppColors.audioWavePrimary,
                radius: radius,
                strokeWidth: widget.strokeWidth,
                barCount: widget.barCount,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CircularVisualizerPainter extends CustomPainter {
  final List<double> audioData;
  final Color color;
  final double radius;
  final double strokeWidth;
  final int barCount;

  _CircularVisualizerPainter({
    required this.audioData,
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final normalizedData = _normalizeAudioData();

    for (int i = 0; i < barCount; i++) {
      final angle = (i * 2 * pi) / barCount;
      final barHeight = i < normalizedData.length
          ? normalizedData[i] * (radius / 2)
          : 0.0;

      final startRadius = radius - barHeight;
      final endRadius = radius + barHeight;

      final startX = center.dx + cos(angle) * startRadius;
      final startY = center.dy + sin(angle) * startRadius;
      final endX = center.dx + cos(angle) * endRadius;
      final endY = center.dy + sin(angle) * endRadius;

      final gradient = LinearGradient(
        colors: [
          color.withOpacity(0.3),
          color,
          color.withOpacity(0.3),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromPoints(
            Offset(startX, startY),
            Offset(endX, endY),
          ),
        )
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  List<double> _normalizeAudioData() {
    if (audioData.isEmpty) return List.filled(barCount, 0.5);

    final maxValue = audioData.reduce((a, b) => a > b ? a : b);
    return audioData.map((value) {
      return maxValue > 0 ? (value / maxValue) : 0.0;
    }).toList();
  }

  @override
  bool shouldRepaint(_CircularVisualizerPainter oldDelegate) {
    return oldDelegate.audioData != audioData;
  }
}