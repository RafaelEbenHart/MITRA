import 'package:flutter/material.dart';

class MeasureDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const MeasureDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<MeasureDropdown> createState() => _MeasureDropdownState();
}

class _MeasureDropdownState extends State<MeasureDropdown> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue ?? 'amount';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedValue,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedValue = newValue;
          });
          widget.onChanged(newValue);
        }
      },
      items: const [
        DropdownMenuItem(
          value: 'amount',
          child: Text('Amount (Jumlah)'),
        ),
        DropdownMenuItem(
          value: 'weight',
          child: Text('Weight (Berat)'),
        ),
      ],
    );
  }
}
