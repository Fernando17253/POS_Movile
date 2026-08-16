import 'package:equatable/equatable.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

abstract class PrinterEvent extends Equatable {
  const PrinterEvent();

  @override
  List<Object?> get props => [];
}

class InitPrinterEvent extends PrinterEvent {}

class RefreshPrinterEvent extends PrinterEvent {}

class ScanPrintersEvent extends PrinterEvent {}

class CancelPrinterSearchEvent extends PrinterEvent {} // NUEVO

class DisconnectPrinterEvent extends PrinterEvent {}

class ForgetPrinterEvent extends PrinterEvent {} // NUEVO

class ConnectPrinterEvent extends PrinterEvent {
  final BluetoothInfo device; // Ahora recibe directamente el objeto BluetoothInfo

  const ConnectPrinterEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class TestPrintEvent extends PrinterEvent {
  final String shopName;

  const TestPrintEvent(this.shopName);

  @override
  List<Object?> get props => [shopName];
}