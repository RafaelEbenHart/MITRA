import 'package:flutter/material.dart';
import 'package:mitra/shared/tema/app_colors.dart';

/// Mitra Custom Card Widget
/// Enhanced card with consistent styling and animations
class MitraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final double elevation;
  final double borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final Color? onTapColor;
  final BoxShadow? customShadow;
  final Gradient? gradient;

  const MitraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.backgroundColor = Colors.white,
    this.elevation = 2,
    this.borderRadius = 12,
    this.border,
    this.onTap,
    this.onTapColor,
    this.customShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        gradient: gradient,
        boxShadow: customShadow != null
            ? [customShadow!]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: onTapColor?.withValues(alpha: 0.1),
            highlightColor: onTapColor?.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

/// Outlined card variant
class MitraOutlinedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback? onTap;

  const MitraOutlinedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderColor = const Color(0xFFE5E7EB),
    this.borderWidth = 1,
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MitraCard(
      padding: padding,
      margin: margin,
      backgroundColor: Colors.white,
      elevation: 0,
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      onTap: onTap,
      child: child,
    );
  }
}

/// Elevated card with more shadow
class MitraElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const MitraElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.backgroundColor = Colors.white,
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MitraCard(
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      elevation: 8,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }
}

/// Tonal card - used for secondary/subtle emphasis
class MitraTonalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color tonalColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const MitraTonalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.tonalColor = const Color(0xFFF5F5F5),
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MitraCard(
      padding: padding,
      margin: margin,
      backgroundColor: tonalColor,
      elevation: 0,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }
}

/// Filled card with accent color
class MitraFilledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? onTapColor;

  const MitraFilledCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.backgroundColor = const Color(0xFF997950),
    this.borderRadius = 12,
    this.onTap,
    this.onTapColor,
  });

  @override
  Widget build(BuildContext context) {
    return MitraCard(
      padding: padding,
      margin: margin,
      backgroundColor: backgroundColor,
      elevation: 4,
      borderRadius: borderRadius,
      onTap: onTap,
      onTapColor: onTapColor ?? backgroundColor,
      child: child,
    );
  }
}

/// Status card - for alerts and notifications
class MitraStatusCard extends StatelessWidget {
  final Widget child;
  final StatusType statusType;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const MitraStatusCard({
    super.key,
    required this.child,
    this.statusType = StatusType.info,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderRadius = 12,
    this.onTap,
  });

  Color _getBackgroundColor() {
    switch (statusType) {
      case StatusType.success:
        return AppColors.successLight;
      case StatusType.error:
        return AppColors.errorLight;
      case StatusType.warning:
        return AppColors.warningLight;
      case StatusType.info:
        return AppColors.infoLight;
    }
  }

  Color _getBorderColor() {
    switch (statusType) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.error:
        return AppColors.error;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MitraCard(
      padding: padding,
      margin: margin,
      backgroundColor: _getBackgroundColor(),
      elevation: 0,
      borderRadius: borderRadius,
      border: Border.all(
        color: _getBorderColor(),
        width: 1.5,
      ),
      onTap: onTap,
      child: child,
    );
  }
}

enum StatusType { success, error, warning, info }
