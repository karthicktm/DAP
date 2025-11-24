import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;
  final double blur;
  final double borderWidth;
  final Color? borderColor;

  const GlassmorphicCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.blur = 10.0,
    this.borderWidth = 1.0,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF1A1B3A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? const Color(0xFF8B5CF6).withOpacity(0.2),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: blur,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}