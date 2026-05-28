import 'package:flutter/material.dart';
import 'package:mitra/modul/inventori/domain/entities/invoice.dart';
import 'package:mitra/shared/format/price_formatter.dart';

class InvoiceItemRow extends StatefulWidget {
  final InvoiceItem item;
  final Function(double) onQuantityChanged;
  final Function(String, dynamic)? onFieldChanged;
  final VoidCallback onRemove;

  const InvoiceItemRow({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    this.onFieldChanged,
    required this.onRemove,
  });

  @override
  State<InvoiceItemRow> createState() => _InvoiceItemRowState();
}

class _InvoiceItemRowState extends State<InvoiceItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _discountController;
  late TextEditingController _costPriceController;
  late TextEditingController _costPerUnitController;

  static const Color _customBrown = Color(0xFF997950);

  @override
  void initState() {
    super.initState();

    String qtyText;
    if (widget.item.measureType == 'weight') {
      qtyText = widget.item.quantity.toString();
    } else {
      qtyText = widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toString();
    }

    String discText = '';
    if (widget.item.discount != null) {
      discText = widget.item.discount! % 1 == 0
          ? widget.item.discount!.toInt().toString()
          : widget.item.discount!.toString();
    }

    String costPriceText = '';
    if (widget.item.costPrice != null) {
      costPriceText = widget.item.costPrice! % 1 == 0
          ? widget.item.costPrice!.toInt().toString()
          : widget.item.costPrice!.toString();
    }

    String costPerUnitText = '';
    if (widget.item.costPerUnit != null) {
      costPerUnitText = widget.item.costPerUnit! % 1 == 0
          ? widget.item.costPerUnit!.toInt().toString()
          : widget.item.costPerUnit!.toString();
    }

    _qtyController = TextEditingController(text: qtyText);
    _discountController = TextEditingController(text: discText);
    _costPriceController = TextEditingController(text: costPriceText);
    _costPerUnitController = TextEditingController(text: costPerUnitText);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _discountController.dispose();
    _costPriceController.dispose();
    _costPerUnitController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String fieldType,
    TextInputType keyboardType =
        const TextInputType.numberWithOptions(decimal: true),
    String? suffixText,
    String? prefixText,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        suffixText: suffixText,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onSubmitted: (val) {
        final parsed = double.tryParse(val.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) {
          widget.onFieldChanged?.call(fieldType, parsed);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        // ── Custom trailing: arrow icon in brand brown (no PopupMenuButton) ──
        trailing: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _customBrown,
        ),
        iconColor: _customBrown,
        collapsedIconColor: _customBrown,
        title: Text(
          widget.item.product.namaBarang,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total: ${formatIdr(widget.item.subtotal)}',
          style: TextStyle(color: Colors.grey[700]),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── 1. Jumlah ──────────────────────────────────────────────────────
          _buildFieldLabel('Jumlah'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _qtyController,
            fieldType: 'quantity',
            suffixText: widget.item.measureType == 'weight' ? 'kg' : 'pcs',
            hintText: 'Masukkan jumlah',
          ),
          const SizedBox(height: 16),

          // ── 2. Satuan (custom smooth slide-down dropdown) ─────────────────
          _buildFieldLabel('Satuan'),
          const SizedBox(height: 8),
          _SmoothDropdown(
            value: widget.item.measureType.isEmpty
                ? 'pcs'
                : widget.item.measureType,
            accentColor: _customBrown,
            items: const [
              _SmoothDropdownItem(value: 'pcs', label: 'Pcs (Satuan)'),
              _SmoothDropdownItem(value: 'weight', label: 'Kg (Timbangan)'),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.onFieldChanged?.call('measureType', value);
              }
            },
          ),
          const SizedBox(height: 16),

          // ── 3. Harga Beli per Unit ─────────────────────────────────────────
          _buildFieldLabel('Harga Beli'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _costPriceController,
            fieldType: 'costPrice',
            prefixText: 'Rp ',
            hintText: 'Masukkan harga beli',
          ),
          const SizedBox(height: 16),

          // ── 4. Per Berapa Pcs/Kg ───────────────────────────────────────────
          _buildFieldLabel('Per Berapa Pcs/Kg'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _costPerUnitController,
            fieldType: 'costPerUnit',
            suffixText: widget.item.measureType == 'weight' ? 'kg' : 'pcs',
            hintText: 'e.g. 5',
          ),
          const SizedBox(height: 16),

          // ── 5. Tanggal Kadaluwarsa (date picker button) ────────────────────
          _buildFieldLabel('Tanggal Kadaluwarsa'),
          const SizedBox(height: 8),
          _ExpiryDatePicker(
            initialDate: widget.item.expirationDate,
            onDateSelected: (date) {
              widget.onFieldChanged?.call('expirationDate', date);
            },
          ),
          const SizedBox(height: 16),

          // ── 6. Diskon ──────────────────────────────────────────────────────
          _buildFieldLabel('Diskon (%)'),
          const SizedBox(height: 8),
          TextField(
            controller: _discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: _customBrown),
            decoration: InputDecoration(
              hintText: '0.00',
              suffixText: '%',
              suffixStyle: const TextStyle(color: _customBrown),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (val) {
              final parsed = double.tryParse(val.replaceAll(',', '.'));
              if (parsed != null) {
                widget.onFieldChanged?.call('discount', parsed);
              }
            },
          ),
          const SizedBox(height: 16),

          // ── Hapus item ─────────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete, color: Colors.red),
              label:
                  const Text('Hapus Item', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom smooth slide-down dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SmoothDropdownItem {
  final String value;
  final String label;
  const _SmoothDropdownItem({required this.value, required this.label});
}

class _SmoothDropdown extends StatefulWidget {
  final String value;
  final List<_SmoothDropdownItem> items;
  final ValueChanged<String?>? onChanged;
  final Color accentColor;

  const _SmoothDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<_SmoothDropdown> createState() => _SmoothDropdownState();
}

class _SmoothDropdownState extends State<_SmoothDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;
  late Animation<double> _arrowAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _arrowAnim = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _select(String value) {
    widget.onChanged?.call(value);
    setState(() => _isOpen = false);
    _animController.reverse();
  }

  String get _currentLabel => widget.items
      .firstWhere(
        (i) => i.value == widget.value,
        orElse: () => widget.items.first,
      )
      .label;

  @override
  Widget build(BuildContext context) {
    final isOpen = _isOpen;
    final borderColor = isOpen ? widget.accentColor : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Trigger ─────────────────────────────────────────────────────────
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor,
                width: isOpen ? 1.5 : 1.0,
              ),
              borderRadius: isOpen
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    )
                  : BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                RotationTransition(
                  turns: _arrowAnim,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Slide-down options panel ─────────────────────────────────────────
        SizeTransition(
          sizeFactor: _expandAnim,
          axisAlignment: -1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: widget.accentColor, width: 1.5),
                right: BorderSide(color: widget.accentColor, width: 1.5),
                bottom: BorderSide(color: widget.accentColor, width: 1.5),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = item.value == widget.value;
                final isLast = index == widget.items.length - 1;
                return InkWell(
                  onTap: () => _select(item.value),
                  borderRadius: isLast
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        )
                      : BorderRadius.zero,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.accentColor.withOpacity(0.08)
                          : Colors.transparent,
                      border: !isLast
                          ? Border(
                              bottom: BorderSide(color: Colors.grey.shade200))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isSelected ? widget.accentColor : null,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded,
                              size: 16, color: widget.accentColor),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Inline date picker widget ────────────────────────────────────────────────
class _ExpiryDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const _ExpiryDatePicker({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_ExpiryDatePicker> createState() => _ExpiryDatePickerState();
}

class _ExpiryDatePickerState extends State<_ExpiryDatePicker> {
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  String get _label {
    if (_selected == null) return 'Pilih Tanggal';
    return '${_selected!.day.toString().padLeft(2, '0')}/'
        '${_selected!.month.toString().padLeft(2, '0')}/'
        '${_selected!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today_outlined, size: 16),
        label: Text(_label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: BorderSide(color: Colors.grey[400]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selected ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
          );
          if (picked != null) {
            setState(() => _selected = picked);
            widget.onDateSelected(picked);
          }
        },
      ),
    );
  }
}
