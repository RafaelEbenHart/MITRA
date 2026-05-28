import 'package:flutter/material.dart';
import 'package:mitra/shared/tema/app_colors.dart';
import 'package:mitra/shared/tema/app_typography.dart';

/// Mitra Custom Button Widget
/// Replaces PrimaryButton with enhanced features while maintaining UI/UX
class MitraButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;
  final TextStyle? textStyle;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MitraButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.elevation = 4.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    this.isFullWidth = true,
    this.textStyle,
    this.isLoading = false,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = foregroundColor ?? Colors.white;

    final effectivePadding = _getPaddingForSize(size);
    final effectiveTextStyle = textStyle ?? AppTypography.labelLarge;

    if (variant == ButtonVariant.outlined) {
      return _buildOutlinedButton(
        context,
        bgColor,
        fgColor,
        effectivePadding,
        effectiveTextStyle,
      );
    } else if (variant == ButtonVariant.text) {
      return _buildTextButton(
        context,
        bgColor,
        fgColor,
        effectivePadding,
        effectiveTextStyle,
      );
    }

    // Default: Filled variant
    return _buildFilledButton(
      context,
      bgColor,
      fgColor,
      effectivePadding,
      effectiveTextStyle,
    );
  }

  Widget _buildFilledButton(
    BuildContext context,
    Color bgColor,
    Color fgColor,
    EdgeInsetsGeometry padding,
    TextStyle textStyle,
  ) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: onPressed != null ? bgColor : AppColors.disabled,
      foregroundColor: onPressed != null ? fgColor : AppColors.textDisabled,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: elevation,
      shadowColor: bgColor.withValues(alpha: 0.4),
      minimumSize: isFullWidth ? const Size.fromHeight(44) : null,
      disabledBackgroundColor: AppColors.disabled,
      disabledForegroundColor: AppColors.textDisabled,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: fgColor,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: textStyle.copyWith(color: fgColor),
        ),
        style: style,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: fgColor,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: textStyle.copyWith(color: fgColor),
            ),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context,
    Color borderColor,
    Color textColor,
    EdgeInsetsGeometry padding,
    TextStyle textStyle,
  ) {
    final style = OutlinedButton.styleFrom(
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      side: BorderSide(
        color: onPressed != null ? borderColor : AppColors.disabled,
        width: 2,
      ),
      minimumSize: isFullWidth ? const Size.fromHeight(44) : null,
    );

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: textColor,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: textStyle.copyWith(color: textColor),
            ),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    Color textColor,
    Color _,
    EdgeInsetsGeometry padding,
    TextStyle textStyle,
  ) {
    final style = TextButton.styleFrom(
      padding: padding,
      minimumSize: isFullWidth ? const Size.fromHeight(44) : null,
    );

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: textColor,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: textStyle.copyWith(color: textColor),
            ),
    );
  }

  EdgeInsetsGeometry _getPaddingForSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(vertical: 8, horizontal: 16);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(vertical: 12, horizontal: 24);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(vertical: 16, horizontal: 32);
    }
  }
}

/// Button size enum
enum ButtonSize { small, medium, large }

/// Button variant enum
enum ButtonVariant { filled, outlined, text }

/// Shorthand constructors for common button types
class MitraButtons {
  /// Primary filled button
  static MitraButton primary({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = true,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
  }) =>
      MitraButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        size: size,
        variant: ButtonVariant.filled,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      );

  /// Success button
  static MitraButton success({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = true,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
  }) =>
      MitraButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        size: size,
        variant: ButtonVariant.filled,
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
      );

  /// Error button
  static MitraButton error({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = true,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
  }) =>
      MitraButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        size: size,
        variant: ButtonVariant.filled,
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      );

  /// Warning button
  static MitraButton warning({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = true,
    bool isLoading = false,
    ButtonSize size = ButtonSize.medium,
  }) =>
      MitraButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        size: size,
        variant: ButtonVariant.filled,
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      );

  /// Outlined button
  static MitraButton outlined({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = true,
    bool isLoading = false,
    Color? borderColor,
    ButtonSize size = ButtonSize.medium,
  }) =>
      MitraButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        size: size,
        variant: ButtonVariant.outlined,
        backgroundColor: borderColor ?? AppColors.primary,
      );

  /// Text button (no background)
  static MitraButton text({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isFullWidth = false,
    bool isLoading = false,
    Color? textColor,
    ButtonSize size = ButtonSize.medium,
  }) =>
      MitraButton(
        onPressed: onPressed,
        label: label,
        icon: icon,
        isFullWidth: isFullWidth,
        isLoading: isLoading,
        size: size,
        variant: ButtonVariant.text,
        foregroundColor: textColor ?? AppColors.primary,
      );
}
