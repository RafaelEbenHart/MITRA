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
    required String total,
    required String createdBy,
    required String footer,
  }) async {
    if (!_isConnected) return;

    const int lineWidth = 32;
    const int nameWidth = 14;
    const int priceWidth = 9;
    const int totalWidth = 9;

    List<int> bytes = [];
    bytes += EscPos.init;

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

    bytes += EscPos.alignLeft;
    bytes += _textToBytes(_formatColumns(
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

    for (var item in items) {
      String name = item['name'].toString();
      double qtyNum = (item['qty'] as num).toDouble();
      String measureType = item['measureType'].toString();
      String price = item['price'].toString().replaceAll('Rp ', 'Rp');
      String totalItem = item['total'].toString().replaceAll('Rp ', 'Rp');

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

      bytes += _textToBytes(_formatColumns(
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

    bytes += EscPos.alignRight;
    bytes += EscPos.boldOn;
    bytes += _textToBytes('TOTAL: $total');
    bytes += EscPos.lineFeed;
    bytes += EscPos.boldOff;
    bytes += EscPos.lineFeed;

    if (createdBy.isNotEmpty) {
      bytes += EscPos.alignLeft;
      bytes += EscPos.lineFeed;
      bytes += EscPos.lineFeed;
    }

    bytes += EscPos.alignCenter;
    bytes += _textToBytes(footer);
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;
    bytes += EscPos.lineFeed;

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  List<int> _textToBytes(String text) {
    // Should verify encoding, but Latin-1 usually works for basic printers
    return List.from(text.codeUnits);
  }

  String _formatColumns({
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
        ? middle.substring(0, middleWidth)
        : middle.padLeft(middleWidth);
    final rightPart = right.length > rightWidth
        ? right.substring(0, rightWidth)
        : right.padLeft(rightWidth);

    return '$leftPart$middlePart$rightPart';
  }
}
