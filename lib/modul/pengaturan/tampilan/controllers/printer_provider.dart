import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repos/printer_repository.dart';
import '../controllers/printer_state.dart';
import '../../../../infrastruktur/injeksi/service_locator.dart' as di;

class PrinterNotifier extends StateNotifier<PrinterState> {
  final PrinterRepository repository;

  PrinterNotifier({required this.repository}) : super(const PrinterState());

  void initPrinter() {
    final mac = repository.getSavedPrinterMac();
    final name = repository.getSavedPrinterName();
    state = state.copyWith(
      status: PrinterStatus.initial,
      connectedMac: mac,
      connectedName: name,
    );
  }

  Future<void> refreshPrinter() async {
    if (state.status == PrinterStatus.connected) {
      state = state.copyWith(
        status: PrinterStatus.connected,
        errorMessage: 'Printer telah terhubung',
        clearError: false,
      );
      return;
    }

    state = state.copyWith(status: PrinterStatus.scanning, clearError: true);
    try {
      final devices = await repository.scanDevices();
      if (devices.isEmpty) {
        state = state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'Tidak dapat menemukan Perangkat',
          devices: [],
        );
        return;
      }

      bool connected = false;
      for (final device in devices) {
        final success = await repository.connect(device.macAdress);
        if (success) {
          await repository.savePrinterData(device.macAdress, device.name);
          state = state.copyWith(
            status: PrinterStatus.connected,
            connectedMac: device.macAdress,
            connectedName: device.name,
            devices: devices,
            clearError: true,
          );
          connected = true;
          break;
        }
      }

      if (!connected) {
        state = state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'Tidak dapat terhubung ke printer',
          devices: devices,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: PrinterStatus.scanFailure,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> scanPrinters() async {
    state = state.copyWith(status: PrinterStatus.scanning, clearError: true);
    try {
      final devices = await repository.scanDevices();
      state = state.copyWith(
        status: PrinterStatus.scanSuccess,
        devices: devices,
      );
    } catch (e) {
      state = state.copyWith(
        status: PrinterStatus.scanFailure,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> connectPrinter(String mac, String name) async {
    state = state.copyWith(status: PrinterStatus.connecting, clearError: true);
    final success = await repository.connect(mac);
    if (success) {
      await repository.savePrinterData(mac, name);
      state = state.copyWith(
        status: PrinterStatus.connected,
        connectedMac: mac,
        connectedName: name,
      );
    } else {
      state = state.copyWith(
        status: PrinterStatus.connectionFailure,
        errorMessage: 'Gagal terhubung ke printer',
      );
    }
  }

  Future<void> disconnectPrinter() async {
    await repository.disconnect();
    await repository.clearPrinterData();
    state = PrinterState(
      status: PrinterStatus.disconnected,
      devices: state.devices,
    );
  }

  Future<void> testPrint(String shopName) async {
    state = state.copyWith(status: PrinterStatus.testPrinting);
    await repository.testPrint(shopName);
    state = state.copyWith(status: PrinterStatus.scanSuccess);
  }
}

final printerNotifierProvider =
    StateNotifierProvider<PrinterNotifier, PrinterState>(
  (ref) => PrinterNotifier(repository: di.sl<PrinterRepository>()),
);


