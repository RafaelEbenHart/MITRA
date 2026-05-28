import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../../infrastruktur/penyimpanan/firebase_database.dart';
import '../../../../shared/format/printer_config.dart';
import '../../domain/repos/printer_repository.dart';

class PrinterRepositoryImpl implements PrinterRepository {
  final PrinterHelper _printerHelper = PrinterHelper();

  @override
  Future<List<BluetoothInfo>> scanDevices() async {
    if (await _printerHelper.checkPermission()) {
      return await _printerHelper.getBondedDevices();
    }
    throw Exception('Izin akses Bluetooth tidak diberikan');
  }

  @override
  Future<bool> connect(String macAddress) async {
    return await _printerHelper.connect(macAddress);
  }

  @override
  Future<bool> disconnect() async {
    return await _printerHelper.disconnect();
  }

  static const String _printerDoc = 'printer_data';

  @override
  String? getSavedPrinterMac() {
    // This method is now synchronous for interface compatibility, but Firestore read is async.
    // In real app, we should refactor interface to async. For now return null and rely on getSavedPrinterDataAsync in app layer.
    return null;
  }

  @override
  String? getSavedPrinterName() {
    return null;
  }

  Future<Map<String, String>?> getSavedPrinterDataAsync() async {
    if (!FirebaseDatabase.isFirebaseAvailable) {
      return null;
    }

    final doc =
        await FirebaseDatabase.settingsCollection().doc(_printerDoc).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return {
        'printer_mac': (data['printer_mac'] as String?) ?? '',
        'printer_name': (data['printer_name'] as String?) ?? '',
      };
    }
    return null;
  }

  @override
  Future<void> savePrinterData(String mac, String name) async {
    if (!FirebaseDatabase.isFirebaseAvailable) {
      return;
    }

    await FirebaseDatabase.settingsCollection().doc(_printerDoc).set({
      'printer_mac': mac,
      'printer_name': name,
    });
  }

  @override
  Future<void> clearPrinterData() async {
    if (!FirebaseDatabase.isFirebaseAvailable) {
      return;
    }

    await FirebaseDatabase.settingsCollection().doc(_printerDoc).delete();
  }

  @override
  Future<void> testPrint(String shopName) async {
    await _printerHelper
        .printText("Test Print\n\n$shopName\n\n----------------\n\n");
  }
}
