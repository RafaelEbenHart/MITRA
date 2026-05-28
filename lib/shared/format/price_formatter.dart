import 'package:intl/intl.dart';

String formatIdr(num value) {
  final whole = value.truncate();
  final formattedWhole = NumberFormat.decimalPattern('id_ID').format(whole);

  if (value == whole) {
    return 'Rp $formattedWhole';
  }

  final raw = value.toStringAsFixed(2);
  final parts = raw.split('.');
  var decimals = parts.length > 1 ? parts[1] : '';
  decimals = decimals.replaceFirst(RegExp(r'0+$'), '');

  if (decimals.isEmpty) {
    return 'Rp $formattedWhole';
  }

  return 'Rp $formattedWhole,$decimals';
}
