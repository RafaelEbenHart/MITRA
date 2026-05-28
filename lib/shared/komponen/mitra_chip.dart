import 'package:flutter/material.dart';
import 'package:mitra/shared/tema/app_colors.dart';
import 'package:mitra/shared/tema/app_typography.dart';

/// Mitra Custom Chip Widget
/// Filter, input, or action chip with consistent styling
class MitraChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool selected;
  final ChipVariant variant;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? labelStyle;

  const MitraChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.onDelete,
    this.selected = false,
    this.variant = ChipVariant.filled,
    this.backgroundColor,
    this.selectedColor,
    this.textColor,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = selected
        ? (selectedColor ?? AppColors.primary)
        : (backgroundColor ?? AppColors.neutral200);
    final effectiveTextColor =
        textColor ?? (selected ? Colors.white : AppColors.textPrimary);

    if (variant == ChipVariant.outlined) {
      return _buildOutlinedChip(effectiveBgColor, effectiveTextColor);
    } else if (variant == ChipVariant.tonal) {
      return _buildTonalChip(effectiveBgColor, effectiveTextColor);
    }

    // Default: Filled variant
    return _buildFilledChip(effectiveBgColor, effectiveTextColor);
  }

  Widget _buildFilledChip(Color bgColor, Color textColor) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: (labelStyle ?? AppTypography.labelMedium).copyWith(
                  color: textColor,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close, color: textColor, size: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedChip(Color borderColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: borderColor, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: (labelStyle ?? AppTypography.labelMedium).copyWith(
                    color: borderColor,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.close, color: borderColor, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTonalChip(Color tonalColor, Color textColor) {
    return Material(
      color: tonalColor.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: tonalColor, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: (labelStyle ?? AppTypography.labelMedium).copyWith(
                  color: tonalColor,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close, color: tonalColor, size: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Input chip for text input in a field
class MitraInputChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final TextStyle? labelStyle;

  const MitraInputChip({
    super.key,
    required this.label,
    this.onDelete,
    this.onTap,
    this.backgroundColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return MitraChip(
      label: label,
      onDelete: onDelete,
      onTap: onTap,
      backgroundColor: backgroundColor ?? AppColors.primary,
      textColor: Colors.white,
      variant: ChipVariant.filled,
      labelStyle: labelStyle,
    );
  }
}

/// Filter chip for filtering options
class MitraFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;

  const MitraFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return MitraChip(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onSelected,
      variant: ChipVariant.filled,
      backgroundColor: AppColors.neutral200,
      selectedColor: AppColors.primary,
      textColor: selected ? Colors.white : AppColors.textPrimary,
    );
  }
}

/// Choice chip for single selection
class MitraChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;

  const MitraChoiceChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return MitraChip(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onSelected,
      variant: ChipVariant.outlined,
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      textColor: selected ? Colors.white : AppColors.textPrimary,
    );
  }
}

/// Status chip - for displaying status badges
class MitraStatusChip extends StatelessWidget {
  final String label;
  final StatusChipType type;
  final IconData? icon;
  final VoidCallback? onTap;

  const MitraStatusChip({
    super.key,
    required this.label,
    this.type = StatusChipType.info,
    this.icon,
    this.onTap,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case StatusChipType.success:
        return AppColors.success;
      case StatusChipType.error:
        return AppColors.error;
      case StatusChipType.warning:
        return AppColors.warning;
      case StatusChipType.info:
        return AppColors.info;
      case StatusChipType.pending:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MitraChip(
      label: label,
      icon: icon,
      onTap: onTap,
      backgroundColor: _getBackgroundColor(),
      textColor: Colors.white,
      variant: ChipVariant.filled,
    );
  }
}

/// Chip list wrapper for managing multiple chips
class MitraChipList extends StatefulWidget {
  final List<String> items;
  final List<String>? selectedItems;
  final ValueChanged<List<String>>? onSelectionChanged;
  final bool multiSelect;
  final ChipListType listType;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  const MitraChipList({
    super.key,
    required this.items,
    this.selectedItems,
    this.onSelectionChanged,
    this.multiSelect = true,
    this.listType = ChipListType.filter,
    this.alignment = WrapAlignment.start,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  State<MitraChipList> createState() => _MitraChipListState();
}

class _MitraChipListState extends State<MitraChipList> {
  late List<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = widget.selectedItems ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: widget.alignment,
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: widget.items.map((item) {
        final isSelected = _selectedItems.contains(item);

        if (widget.listType == ChipListType.filter) {
          return MitraFilterChip(
            label: item,
            selected: isSelected,
            onSelected: () {
              setState(() {
                if (widget.multiSelect) {
                  if (isSelected) {
                    _selectedItems.remove(item);
                  } else {
                    _selectedItems.add(item);
                  }
                } else {
                  if (isSelected) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems = [item];
                  }
                }
              });
              widget.onSelectionChanged?.call(_selectedItems);
            },
          );
        } else {
          return MitraChoiceChip(
            label: item,
            selected: isSelected,
            onSelected: () {
              setState(() {
                if (widget.multiSelect) {
                  if (isSelected) {
                    _selectedItems.remove(item);
                  } else {
                    _selectedItems.add(item);
                  }
                } else {
                  if (isSelected) {
                    _selectedItems.clear();
                  } else {
                    _selectedItems = [item];
                  }
                }
              });
              widget.onSelectionChanged?.call(_selectedItems);
            },
          );
        }
      }).toList(),
    );
  }
}

enum ChipVariant { filled, outlined, tonal }

enum ChipListType { filter, choice }

enum StatusChipType { success, error, warning, info, pending }
