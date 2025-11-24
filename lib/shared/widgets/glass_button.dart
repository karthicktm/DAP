import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Modern glassmorphic button with blur effect and gradient
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool isLoading;
  final double elevation;
  final BorderSide? border;

  const GlassButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.isLoading = false,
    this.elevation = 8.0,
    this.border,
  }) : super(key: key);

  factory GlassButton.primary({
    required String text,
    VoidCallback? onPressed,
    Widget? child,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GlassButton(
      text: text,
      onPressed: onPressed,
      child: child,
      width: width,
      height: height,
      isLoading: isLoading,
      gradient: const LinearGradient(
        colors: AppColors.buttonGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  factory GlassButton.secondary({
    required String text,
    VoidCallback? onPressed,
    Widget? child,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GlassButton(
      text: text,
      onPressed: onPressed,
      child: child,
      width: width,
      height: height,
      isLoading: isLoading,
      backgroundColor: AppColors.surface.withOpacity(0.3),
      border: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      elevation: 4.0,
    );
  }

  factory GlassButton.outline({
    required String text,
    VoidCallback? onPressed,
    Widget? child,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GlassButton(
      text: text,
      onPressed: onPressed,
      child: child,
      width: width,
      height: height,
      isLoading: isLoading,
      backgroundColor: Colors.transparent,
      border: BorderSide(color: AppColors.primary, width: 2),
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: width,
      height: height ?? 50,
      decoration: BoxDecoration(
        gradient: isEnabled ? gradient : _getDisabledGradient(),
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(25),
        border: border,
        boxShadow: elevation > 0 ? [
          BoxShadow(
            color: isEnabled
                ? (gradient?.colors.first ?? AppColors.primary).withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: borderRadius ?? BorderRadius.circular(25),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: isLoading
                  ? _buildLoadingIndicator()
                  : child ?? _buildButtonText(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonText() {
    return Text(
      text,
      style: AppTextStyles.button.copyWith(
        color: backgroundColor != null ? AppColors.primary : Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          backgroundColor != null ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }

  Gradient _getDisabledGradient() {
    return LinearGradient(
      colors: [
        AppColors.textDisabled.withOpacity(0.3),
        AppColors.textDisabled.withOpacity(0.2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// Glassmorphic floating action button
class GlassFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Gradient? gradient;
  final double size;

  const GlassFab({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.gradient,
    this.size = 56.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          colors: AppColors.buttonGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}