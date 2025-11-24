import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Simplified glassmorphic button that works with minimal dependencies
class SimpleGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SimpleGlassButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: width,
      height: height ?? 50,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: AppColors.buttonGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  AppColors.textDisabled.withOpacity(0.3),
                  AppColors.textDisabled.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(25),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          foregroundColor ?? Colors.white,
                        ),
                      ),
                    )
                  : child ??
                      Text(
                        text,
                        style: AppTextStyles.button.copyWith(
                          color: foregroundColor ?? Colors.white,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}