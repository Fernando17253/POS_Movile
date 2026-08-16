import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/printer_repository.dart';
import 'printer_event.dart';
import 'printer_state.dart';

class PrinterBloc extends Bloc<PrinterEvent, PrinterState> {
  final PrinterRepository repository;

  PrinterBloc({required this.repository}) : super(const PrinterState()) {
    on<InitPrinterEvent>(_onInit);
    on<RefreshPrinterEvent>(_onRefresh);
    on<ScanPrintersEvent>(_onScan);
    on<CancelPrinterSearchEvent>(_onCancelSearch); // NUEVO
    on<ConnectPrinterEvent>(_onConnect);
    on<DisconnectPrinterEvent>(_onDisconnect);
    on<ForgetPrinterEvent>(_onForget); // NUEVO
    on<TestPrintEvent>(_onTestPrint);
  }

  void _onInit(InitPrinterEvent event, Emitter<PrinterState> emit) {
    final mac = repository.getSavedPrinterMac();
    final name = repository.getSavedPrinterName();
    emit(state.copyWith(
      status: mac != null ? PrinterStatus.disconnected : PrinterStatus.initial,
      connectedMac: mac,
      connectedName: name,
    ));
  }

  Future<void> _onRefresh(RefreshPrinterEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.scanning, clearError: true));
    try {
      final devices = await repository.scanDevices();
      if (devices.isEmpty) {
        emit(state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'No se encontraron dispositivos vinculados.',
          devices: [],
        ));
        return;
      }

      bool connected = false;
      for (var device in devices) {
        final success = await repository.connect(device.macAdress);
        if (success) {
          await repository.savePrinterData(device.macAdress, device.name);
          emit(state.copyWith(
            status: PrinterStatus.connected,
            connectedMac: device.macAdress,
            connectedName: device.name,
            devices: devices,
            clearError: true,
          ));
          connected = true;
          break;
        }
      }

      if (!connected) {
        emit(state.copyWith(
          status: PrinterStatus.scanFailure,
          errorMessage: 'No se pudo conectar a ningún dispositivo.',
          devices: devices,
        ));
      }
    } catch (e) {
      emit(state.copyWith(status: PrinterStatus.scanFailure, errorMessage: e.toString()));
    }
  }

  Future<void> _onScan(ScanPrintersEvent event, Emitter<PrinterState> emit) async {
    // Este evento solo escanea (ideal para levantar el menú visual de selección)
    emit(state.copyWith(status: PrinterStatus.scanning, clearError: true));
    try {
      final devices = await repository.scanDevices();
      emit(state.copyWith(
        status: PrinterStatus.scanSuccess,
        devices: devices,
      ));
    } catch (e) {
      emit(state.copyWith(status: PrinterStatus.scanFailure, errorMessage: e.toString()));
    }
  }

  void _onCancelSearch(CancelPrinterSearchEvent event, Emitter<PrinterState> emit) {
    // Retorna al estado anterior (Conectado o Desconectado) y cancela el spinner
    emit(state.copyWith(
      status: state.connectedMac != null ? PrinterStatus.disconnected : PrinterStatus.initial,
      clearError: true,
    ));
  }

  Future<void> _onConnect(ConnectPrinterEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.connecting, clearError: true));
    final success = await repository.connect(event.device.macAdress);
    if (success) {
      await repository.savePrinterData(event.device.macAdress, event.device.name);
      emit(state.copyWith(
        status: PrinterStatus.connected,
        connectedMac: event.device.macAdress,
        connectedName: event.device.name,
      ));
    } else {
      emit(state.copyWith(
        status: PrinterStatus.connectionFailure,
        errorMessage: 'Fallo al conectar con la impresora.',
      ));
    }
  }

  Future<void> _onDisconnect(DisconnectPrinterEvent event, Emitter<PrinterState> emit) async {
    await repository.disconnect();
    // Solo desconectamos, NO borramos la memoria de la impresora guardada
    emit(state.copyWith(
      status: PrinterStatus.disconnected,
    ));
  }

  Future<void> _onForget(ForgetPrinterEvent event, Emitter<PrinterState> emit) async {
    await repository.disconnect();
    await repository.clearPrinterData();
    // Borramos todo y regresamos al estado inicial
    emit(const PrinterState(
      status: PrinterStatus.initial,
      devices: [],
    ));
  }

  Future<void> _onTestPrint(TestPrintEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.testPrinting));
    await repository.testPrint(event.shopName);
    emit(state.copyWith(status: PrinterStatus.connected)); // Regresamos a conectado
  }
}