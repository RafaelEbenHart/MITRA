import 'package:flutter/material.dart';

/// Comprehensive color palette for Mitra POS Application
/// Primary Color: #997950 (Brown/Tan)
/// Designed to maintain existing UI/UX while adding differentiation
class AppColors {
  // ============ PRIMARY PALETTE ============
  /// Main brand color - Brown/Tan
  static const Color primary = Color(0xFF997950);

  /// Darker shade for emphasis
  static const Color primaryDark = Color(0xFF7A5A3E);

  /// Lighter shade for backgrounds
  static const Color primaryLight = Color(0xFFB89968);

  /// Very light shade for hover/focus states
  static const Color primaryVeryLight = Color(0xFFE8DCC8);

  // ============ SECONDARY PALETTE ============
  /// Secondary accent color (same as primary currently)
  static const Color secondary = Color(0xFF997950);

  /// Secondary dark
  static const Color secondaryDark = Color(0xFF7A5A3E);

  /// Secondary light
  static const Color secondaryLight = Color(0xFFB89968);

  // ============ SUCCESS PALETTE ============
  /// Success states
  static const Color success = Color(0xFF10B981);

  /// Success dark
  static const Color successDark = Color(0xFF059669);

  /// Success light
  static const Color successLight = Color(0xFFD1FAE5);

  // ============ ERROR PALETTE ============
  /// Error states
  static const Color error = Color(0xFFEF4444);

  /// Error dark
  static const Color errorDark = Color(0xFFDC2626);

  /// Error light
  static const Color errorLight = Color(0xFFFEE2E2);

  // ============ WARNING PALETTE ============
  /// Warning states
  static const Color warning = Color(0xFFF59E0B);

  /// Warning dark
  static const Color warningDark = Color(0xFFD97706);

  /// Warning light
  static const Color warningLight = Color(0xFFFEF3C7);

  // ============ INFO PALETTE ============
  /// Info states
  static const Color info = Color(0xFF3B82F6);

  /// Info dark
  static const Color infoDark = Color(0xFF1D4ED8);

  /// Info light
  static const Color infoLight = Color(0xFFDBEAFE);

  // ============ NEUTRAL PALETTE ============
  /// Neutral colors for text and backgrounds
  static const Color neutral100 = Color(0xFFFAFAFA);
  static const Color neutral200 = Color(0xFFF5F5F5);
  static const Color neutral300 = Color(0xFFF0F0F0);
  static const Color neutral400 = Color(0xFFE5E5E5);
  static const Color neutral500 = Color(0xFFD0D0D0);
  static const Color neutral600 = Color(0xFFA1A1A1);
  static const Color neutral700 = Color(0xFF737373);
  static const Color neutral800 = Color(0xFF525252);
  static const Color neutral900 = Color(0xFF292929);

  // ============ SEMANTIC COLORS ============
  /// Background colors
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  /// Border colors
  static const Color borderDefault = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF997950);
  static const Color borderError = Color(0xFFEF4444);

  /// Divider colors
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // ============ OVERLAY COLORS ============
  /// Shadow colors with opacity
  static Color shadowDefault = Colors.black.withValues(alpha: 0.08);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.12);
  static Color shadowStrong = Colors.black.withValues(alpha: 0.16);

  /// Overlay colors
  static Color overlay = Colors.black.withValues(alpha: 0.50);
  static Color overlayLight = Colors.black.withValues(alpha: 0.20);

  // ============ STATE COLORS ============
  /// Disabled state
  static const Color disabled = Color(0xFFD1D5DB);

  /// Hover state
  static const Color hover = Color(0xFFF3F4F6);

  /// Focus state
  static Color focus = const Color(0xFF997950).withValues(alpha: 0.10);

  /// Active state
  static const Color active = Color(0xFF997950);

  /// Inactive state
  static const Color inactive = Color(0xFFD1D5DB);

  // ============ BRAND COLORS DARK THEME ============
  /// Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);

  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFC0C0C0);
  static const Color darkTextTertiary = Color(0xFF8A8A8A);

  // ============ UTILITY METHODS ============
  /// Get opacity variant of color
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get color by name (useful for dynamic themes)
  static Color getColorByName(String name) {
    switch (name.toLowerCase()) {
      case 'primary':
        return primary;
      case 'secondary':
        return secondary;
      case 'success':
        return success;
      case 'error':
        return error;
      case 'warning':
        return warning;
      case 'info':
        return info;
      default:
        return primary;
    }
  }
}
