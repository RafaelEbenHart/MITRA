import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitra/shared/tema/app_colors.dart';
import 'package:mitra/shared/tema/app_typography.dart';

/// Mitra Custom Input Field Widget
/// Replaces standard TextField with enhanced features and consistency
class MitraTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? customPrefix;
  final Widget? customSuffix;
  final VoidCallback? onSuffixIconPressed;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? decoration;
  final double borderRadius;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final String? Function(String?)? validator;
  final FormFieldSetter<String>? onSaved;
  final String? initialValue;

  const MitraTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.customPrefix,
    this.customSuffix,
    this.onSuffixIconPressed,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.decoration,
    this.borderRadius = 12,
    this.borderColor = const Color(0xFFE5E7EB),
    this.focusedBorderColor = const Color(0xFF997950),
    this.errorBorderColor = const Color(0xFFEF4444),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.validator,
    this.onSaved,
    this.initialValue,
  });

  @override
  State<MitraTextField> createState() => _MitraTextFieldState();
}

class _MitraTextFieldState extends State<MitraTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ??
        InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          labelStyle: widget.labelStyle ?? AppTypography.labelMedium,
          hintStyle: widget.hintStyle ?? AppTypography.hint,
          prefixIcon: widget.customPrefix != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.customPrefix,
                )
              : (widget.prefixIcon != null ? Icon(widget.prefixIcon) : null),
          suffixIcon: widget.suffixIcon != null || widget.customSuffix != null
              ? _buildSuffixWidget()
              : null,
          border: _buildBorder(widget.borderColor),
          enabledBorder: _buildBorder(widget.borderColor),
          focusedBorder: _buildBorder(widget.focusedBorderColor, width: 2),
          errorBorder: _buildBorder(widget.errorBorderColor),
          focusedErrorBorder: _buildBorder(widget.errorBorderColor, width: 2),
          disabledBorder: _buildBorder(AppColors.disabled),
          contentPadding: widget.contentPadding,
          filled: true,
          fillColor: widget.enabled ? Colors.white : AppColors.neutral100,
          isDense: false,
          counterText: '',
        );

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      decoration: decoration,
      validator: widget.validator,
      onSaved: widget.onSaved,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: _obscureText,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onSubmitted,
      focusNode: _focusNode,
      style: widget.textStyle ?? AppTypography.bodyMedium,
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget? _buildSuffixWidget() {
    if (widget.customSuffix != null) {
      return widget.customSuffix;
    }

    if (widget.suffixIcon == Icons.visibility ||
        widget.suffixIcon == Icons.visibility_off) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return IconButton(
      icon: Icon(widget.suffixIcon),
      onPressed: widget.onSuffixIconPressed,
    );
  }
}

/// Number input field with custom formatting
class MitraNumberField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool allowDecimal;
  final bool readOnly;
  final double borderRadius;

  const MitraNumberField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.maxLength,
    this.allowDecimal = false,
    this.readOnly = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return MitraTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      keyboardType: allowDecimal ? TextInputType.number : TextInputType.number,
      onChanged: onChanged,
      maxLength: maxLength,
      readOnly: readOnly,
      borderRadius: borderRadius,
      inputFormatters: [
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}

/// Phone number input field
class MitraPhoneField extends StatelessWidget {
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const MitraPhoneField({
    super.key,
    this.controller,
    this.errorText,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return MitraTextField(
      controller: controller,
      label: 'Nomor Telepon',
      hint: '08xx xxxx xxxx',
      errorText: errorText,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
      readOnly: readOnly,
      prefixIcon: Icons.phone,
      maxLength: 13,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}

/// Email input field
class MitraEmailField extends StatelessWidget {
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const MitraEmailField({
    super.key,
    this.controller,
    this.errorText,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return MitraTextField(
      controller: controller,
      label: 'Email',
      hint: 'email@example.com',
      errorText: errorText,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
      readOnly: readOnly,
      prefixIcon: Icons.email,
    );
  }
}

/// Password input field
class MitraPasswordField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const MitraPasswordField({
    super.key,
    this.controller,
    this.label = 'Kata Sandi',
    this.errorText,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return MitraTextField(
      controller: controller,
      label: label,
      hint: 'Masukkan kata sandi',
      errorText: errorText,
      keyboardType: TextInputType.visiblePassword,
      onChanged: onChanged,
      readOnly: readOnly,
      prefixIcon: Icons.lock,
      suffixIcon: Icons.visibility,
      obscureText: true,
    );
  }
}

/// Search input field
class MitraSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool readOnly;

  const MitraSearchField({
    super.key,
    this.controller,
    this.hint = 'Cari...',
    this.onChanged,
    this.onClear,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return MitraTextField(
      controller: controller,
      label: '',
      hint: hint,
      keyboardType: TextInputType.text,
      onChanged: onChanged,
      readOnly: readOnly,
      prefixIcon: Icons.search,
      suffixIcon: Icons.close,
      borderRadius: 24,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
}
