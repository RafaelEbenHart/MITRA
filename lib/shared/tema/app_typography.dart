import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system for Mitra POS Application
/// Uses IBM Plex Sans as primary font
class AppTypography {
  // ============ BASE FONT ============
  static TextTheme get baseTextTheme {
    return GoogleFonts.ibmPlexSansTextTheme();
  }

  // ============ DISPLAY STYLES ============
  /// Large display text - for page headers
  static TextStyle get displayLarge {
    return GoogleFonts.ibmPlexSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.5,
    );
  }

  /// Medium display text
  static TextStyle get displayMedium {
    return GoogleFonts.ibmPlexSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.29,
      letterSpacing: 0,
    );
  }

  /// Small display text
  static TextStyle get displaySmall {
    return GoogleFonts.ibmPlexSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.33,
      letterSpacing: 0,
    );
  }

  // ============ HEADLINE STYLES ============
  /// Large headline - major section headers
  static TextStyle get headlineLarge {
    return GoogleFonts.ibmPlexSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.4,
      letterSpacing: 0.15,
    );
  }

  /// Medium headline
  static TextStyle get headlineMedium {
    return GoogleFonts.ibmPlexSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.44,
      letterSpacing: 0,
    );
  }

  /// Small headline
  static TextStyle get headlineSmall {
    return GoogleFonts.ibmPlexSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15,
    );
  }

  // ============ TITLE STYLES ============
  /// Large title
  static TextStyle get titleLarge {
    return GoogleFonts.ibmPlexSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15,
    );
  }

  /// Medium title
  static TextStyle get titleMedium {
    return GoogleFonts.ibmPlexSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.57,
      letterSpacing: 0.1,
    );
  }

  /// Small title
  static TextStyle get titleSmall {
    return GoogleFonts.ibmPlexSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.67,
      letterSpacing: 0.1,
    );
  }

  // ============ BODY STYLES ============
  /// Large body text - main content
  static TextStyle get bodyLarge {
    return GoogleFonts.ibmPlexSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.15,
    );
  }

  /// Medium body text
  static TextStyle get bodyMedium {
    return GoogleFonts.ibmPlexSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
      letterSpacing: 0.25,
    );
  }

  /// Small body text
  static TextStyle get bodySmall {
    return GoogleFonts.ibmPlexSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.4,
    );
  }

  // ============ LABEL STYLES ============
  /// Large label - form labels
  static TextStyle get labelLarge {
    return GoogleFonts.ibmPlexSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.43,
      letterSpacing: 0.1,
    );
  }

  /// Medium label
  static TextStyle get labelMedium {
    return GoogleFonts.ibmPlexSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.67,
      letterSpacing: 0.5,
    );
  }

  /// Small label - small form labels
  static TextStyle get labelSmall {
    return GoogleFonts.ibmPlexSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.45,
      letterSpacing: 0.5,
    );
  }

  // ============ CAPTION STYLES ============
  /// Caption text - helper text, annotations
  static TextStyle get caption {
    return GoogleFonts.ibmPlexSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
    );
  }

  /// Small caption
  static TextStyle get captionSmall {
    return GoogleFonts.ibmPlexSans(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    );
  }

  // ============ CUSTOM STYLES ============
  /// Button text style
  static TextStyle get button {
    return GoogleFonts.ibmPlexSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
    );
  }

  /// Link/Action text style
  static TextStyle get link {
    return GoogleFonts.ibmPlexSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      decoration: TextDecoration.underline,
    );
  }

  /// Error text style
  static TextStyle get error {
    return GoogleFonts.ibmPlexSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.4,
    );
  }

  /// Hint text style
  static TextStyle get hint {
    return GoogleFonts.ibmPlexSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
    );
  }

  // ============ UTILITY METHODS ============
  /// Get text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Get text style with custom size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Get text style with line height
  static TextStyle withLineHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }

  /// Get text style with letter spacing
  static TextStyle withLetterSpacing(TextStyle style, double spacing) {
    return style.copyWith(letterSpacing: spacing);
  }

  /// Combine multiple modifications
  static TextStyle withStyle({
    required TextStyle baseStyle,
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? height,
    double? letterSpacing,
  }) {
    return baseStyle.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

/// Extension methods for easier text style usage
extension TextStyleExtension on TextStyle {
  /// Apply primary color to text style
  TextStyle get primary => copyWith(color: const Color(0xFF997950));

  /// Apply secondary color
  TextStyle get secondary => copyWith(color: const Color(0xFF997950));

  /// Apply success color
  TextStyle get success => copyWith(color: const Color(0xFF10B981));

  /// Apply error color
  TextStyle get error => copyWith(color: const Color(0xFFEF4444));

  /// Apply warning color
  TextStyle get warning => copyWith(color: const Color(0xFFF59E0B));

  /// Apply disabled color
  TextStyle get disabled => copyWith(color: const Color(0xFFD1D5DB));

  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text regular
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add underline
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);

  /// Add line-through
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);

  /// Increase size by multiplier
  TextStyle sizeMultiplier(double multiplier) {
    final currentSize = fontSize ?? 14;
    return copyWith(fontSize: currentSize * multiplier);
  }
}
