import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

class EscPos {
  static const List<int> init = [0x1B, 0x40];
  static const List<int> alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> alignRight = [0x1B, 0x61, 0x02];
  static const List<int> boldOn = [0x1B, 0x45, 0x01];
  static const List<int> boldOff = [0x1B, 0x45, 0x00];
  static const List<int> textNormal = [0x1D, 0x21, 0x00];
  static const List<int> textLarge = [0x1D, 0x21, 0x11];
  static const List<int> lineFeed = [0x0A];
}

class PrinterHelper {
  static final PrinterHelper _instance = PrinterHelper._internal();
  factory PrinterHelper() => _instance;
  PrinterHelper._internal();

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<bool> checkPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<List<BluetoothInfo>> getBondedDevices() async {
    try {
      final List<BluetoothInfo> list =
          await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(String macAddress) async {
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      _isConnected = result;
      return result;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      _isConnected = !result;
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> printText(String text) async {
    if (!_isConnected) return;
    final bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      List<int> bytes = text.codeUnits;
      await PrintBluetoothThermal.writeBytes(bytes);
    }
  }

  // ignore: non_constant_identifier_names
  Future<void> print_format({
    required String shopName,
    required String address,
    required String phone,
    required List<Map<String, dynamic>> items,
    required String subtotal,
    required String totalDiscount,
    required String taxLabel,
    required String taxAmount,
    required String total,
    required String createdBy,
    required String footer,
  }) async {
    if (!_isConnected) return;

    const int lineWidth = 32;
    const int nameWidth = 10;
    const int priceWidth = 9;
    const int totalWidth = 9;

    List<int> bytes = [];
    bytes += EscPos.init;

    // Header
    bytes += EscPos.alignCenter;
    bytes += EscPos.boldOn;
    bytes += EscPos.textLarge;
    bytes += _textToBytes(shopName);
    bytes += EscPos.lineFeed;

    bytes += EscPos.textNormal;
    bytes += EscPos.boldOff;
    if (address.isNotEmpty) {
      bytes += _textToBytes(address);
      bytes += EscPos.lineFeed;
    }
    if (phone.isNotEmpty) {
      bytes += _textToBytes(phone);
      bytes += EscPos.lineFeed;
    }

    String formattedDate =
        DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now());
    bytes += _textToBytes(formattedDate);
    bytes += EscPos.lineFeed;

    final separator = List.filled(lineWidth, '-').join();
    bytes += _textToBytes(separator);
    bytes += EscPos.lineFeed;

    // Header kolom 3 (tanpa diskon)
    bytes += EscPos.alignLeft;
    bytes += _textToBytes(_formatColumns3(
      left: 'Produk',
      middle: 'Harga',
      right: 'SubTotal',
      leftWidth: nameWidth,
      middleWidth: priceWidth,
      rightWidth: totalWidth,
    ));
    bytes += EscPos.lineFeed;
    bytes += _textToBytes(separator);
    bytes += EscPos.lineFeed;

    // Daftar item
    List<Map<String, dynamic>> discountedItems = [];

    for (var item in items) {
      String name = item['name'].toString();
      double qtyNum = (item['qty'] as num).toDouble();
      String measureType = item['measureType'].toString();
      String price = _formatPrice(item['price'].toString());
      String totalItem = _formatPrice(item['total'].toString());

      // Kumpulkan item yang punya diskon
      // Try to parse discount value coming from formatted IDR strings
      // e.g. "Rp 2.250" (Indonesian format uses '.' as thousand sep and ',' as decimal sep)
      String rawDiscount = item['discount'].toString();
      // Keep digits, dots, commas and minus sign
      rawDiscount = rawDiscount.replaceAll(RegExp(r"[^0-9.,\-]"), '');
      // Remove thousand separators (dots) and convert decimal comma to dot
      rawDiscount = rawDiscount.replaceAll('.', '');
      rawDiscount = rawDiscount.replaceAll(',', '.');
      double discountVal = double.tryParse(rawDiscount) ?? 0;
      if (discountVal > 0) {
        discountedItems.add({
          'name': name,
          'qty': qtyNum,
          'measureType': measureType,
          'discount': discountVal,
        });
      }

      String qtyStr;
      if (measureType == 'weight') {
        qtyStr = qtyNum % 1 == 0
            ? '${qtyNum.toInt()}kg'
            : '${qtyNum.toStringAsFixed(2)}kg';
      } else {
        qtyStr = '${qtyNum.toInt()}x';
      }

      String prefix = '$qtyStr $name';
      if (prefix.length > nameWidth) {
        prefix = prefix.substring(0, nameWidth);
      }

      bytes += _textToBytes(_formatColumns3(
        left: prefix,
        middle: price,
        right: totalItem,
        leftWidth: nameWidth,
        middleWidth: priceWidth,
        rightWidth: totalWidth,
      ));
      bytes += EscPos.lineFeed;
    }

    bytes += _textToBytes(separator);
    bytes += EscPos.lineFeed;

    // Subtotal
    bytes += EscPos.alignRight;
    bytes += _textToBytes('SUBTOTAL: ${_formatPrice(subtotal)}');
    bytes += EscPos.lineFeed;

    // Blok diskon per item (jika ada)
    if (discountedItems.isNotEmpty) {
      bytes += EscPos.alignLeft;
      bytes += _textToBytes('DISKON:');
      bytes += EscPos.lineFeed;

      double grandTotalDiscount = 0;
      for (var d in discountedItems) {
        String dName = d['name'].toString();
        double dQty = (d['qty'] as num).toDouble();
        String dMeasure = d['measureType'].toString();
        double dVal = d['discount'] as double;
        grandTotalDiscount += dVal;

        String dQtyStr = dMeasure == 'weight'
            ? (dQty % 1 == 0
                ? '${dQty.toInt()}kg'
                : '${dQty.toStringAsFixed(2)}kg')
            : '${dQty.toInt()}x';

        String label = '- $dName ($dQtyStr)';
        String discountStr = '-${_formatPrice(dVal.toStringAsFixed(0))}';
        bytes += _textToBytes(
          _formatLabelValue(
            label: label,
            value: discountStr,
            lineWidth: lineWidth,
          ),
        );
        bytes += EscPos.lineFeed;
      }

      // Total diskon tanpa tanda "-"
      bytes += EscPos.alignRight;
      bytes += _textToBytes(
        'TOT.DISKON: ${_formatPrice(grandTotalDiscount.toStringAsFixed(0))}',
      );
      bytes += EscPos.lineFeed;
    }

    // Pajak
    bytes += EscPos.alignRight;
    bytes += _textToBytes('$taxLabel: ${_formatPrice(taxAmount)}');
    bytes += EscPos.lineFeed;

    // Total
    bytes += EscPos.boldOn;
    bytes += _textToBytes('TOTAL: ${_formatPrice(total)}');
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;
    bytes += EscPos.lineFeed;

    // Kasir
    if (createdBy.isNotEmpty) {
      bytes += EscPos.alignLeft;
      bytes += _textToBytes('Kasir: $createdBy');
      bytes += EscPos.lineFeed;
      bytes += EscPos.lineFeed;
    }

    // Footer
    bytes += EscPos.alignCenter;
    bytes += _textToBytes(footer);
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  String _formatColumns3({
    required String left,
    required String middle,
    required String right,
    required int leftWidth,
    required int middleWidth,
    required int rightWidth,
  }) {
    final leftPart = left.length > leftWidth
        ? left.substring(0, leftWidth)
        : left.padRight(leftWidth);
    final middlePart = middle.length > middleWidth
        ? middle.substring(middle.length - middleWidth)
        : middle.padLeft(middleWidth);
    final rightPart = right.length > rightWidth
        ? right.substring(right.length - rightWidth)
        : right.padLeft(rightWidth);
    return '$leftPart$middlePart$rightPart';
  }

  String _formatLabelValue({
    required String label,
    required String value,
    required int lineWidth,
  }) {
    int space = lineWidth - label.length - value.length;
    if (space < 1) {
      int maxLabel = lineWidth - value.length - 1;
      label = label.substring(0, maxLabel.clamp(0, label.length));
      space = 1;
    }
    return '$label${' ' * space}$value';
  }

  List<int> _textToBytes(String text) {
    return List.from(text.codeUnits);
  }

  // Harga dengan prefix Rp, tanpa spasi
  String _formatPrice(String value) {
    var formatted = value.trim();
    if (formatted.isEmpty) return 'Rp0';
    formatted = formatted.replaceAll(RegExp(r'^(Rp\s*|rp\s*|RP\s*)'), '');
    formatted = formatted.replaceAll(RegExp(r'^[^0-9]+'), '');
    return 'Rp${formatted.isEmpty ? '0' : formatted}';
  }
}
