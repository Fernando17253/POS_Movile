import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_settings/app_settings.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/printer_bloc.dart';
import '../bloc/printer_event.dart';
import '../bloc/printer_state.dart';

import '../widgets/settings_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrinterBloc>().add(InitPrinterEvent());
  }

  String _printerStatusLabel(PrinterState state) {
    switch (state.status) {
      case PrinterStatus.initial:
      case PrinterStatus.disconnected: return 'Sin impresora conectada';
      case PrinterStatus.scanning: return 'Buscando impresora...';
      case PrinterStatus.scanSuccess: return 'Búsqueda completada';
      case PrinterStatus.scanFailure: return 'No se pudo buscar impresoras';
      case PrinterStatus.connecting: return 'Conectando...';
      case PrinterStatus.connected: return state.connectedName ?? 'Impresora conectada';
      case PrinterStatus.connectionFailure: return 'No se pudo conectar a la impresora';
      case PrinterStatus.testPrinting: return 'Imprimiendo prueba...';
      case PrinterStatus.error: return 'Error de impresora';
    }
  }

  Color _printerStatusColor(PrinterState state) {
    switch (state.status) {
      case PrinterStatus.connected:
      case PrinterStatus.scanSuccess: return Colors.teal;
      case PrinterStatus.scanning:
      case PrinterStatus.connecting:
      case PrinterStatus.testPrinting: return Colors.orange;
      case PrinterStatus.scanFailure:
      case PrinterStatus.connectionFailure:
      case PrinterStatus.error: return Colors.red;
      case PrinterStatus.initial:
      case PrinterStatus.disconnected: return Colors.grey;
    }
  }

  String _printerStatusChipLabel(PrinterState state) {
    switch (state.status) {
      case PrinterStatus.connected: return 'Conectada';
      case PrinterStatus.scanning: return 'Buscando';
      case PrinterStatus.scanSuccess: return 'Lista';
      case PrinterStatus.scanFailure: return 'Fallo de búsqueda';
      case PrinterStatus.connecting: return 'Conectando';
      case PrinterStatus.connectionFailure: return 'Fallo de conexión';
      case PrinterStatus.testPrinting: return 'Imprimiendo';
      case PrinterStatus.error: return 'Error';
      case PrinterStatus.initial:
      case PrinterStatus.disconnected: return 'Desconectada';
    }
  }

  String _buildInitials(String value) {
    final parts = value.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'T';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  void _showDevicesBottomSheet(BuildContext context, List<dynamic> devices) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeviceSelectionBottomSheet(
        devices: devices,
        onDeviceSelected: (device) {
          // Asegúrate de tener este evento en tu BLoC
          context.read<PrinterBloc>().add(ConnectPrinterEvent(device));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<PrinterBloc, PrinterState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.trim().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
            return;
          }
          if (state.status == PrinterStatus.connected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impresora conectada correctamente'), backgroundColor: Colors.green),
            );
          }
          if (state.status == PrinterStatus.scanSuccess) {
            // Nota: Aquí asumo que tu PrinterState tiene una variable "discoveredDevices"
            // De lo contrario, extrae la lista de donde la estés guardando
            final devices = (state as dynamic).discoveredDevices ?? [];
            _showDevicesBottomSheet(context, devices);
          }
        },
        builder: (context, printerState) {
          return BlocBuilder<ShopBloc, ShopState>(
            builder: (context, shopState) {
              String shopName = 'Mi tienda';
              String initials = 'MT';

              if (shopState is ShopLoaded && shopState.shop.name.trim().isNotEmpty) {
                shopName = shopState.shop.name.trim();
                initials = _buildInitials(shopName);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                children: [
                  ShopHeaderCard(
                    shopName: shopName,
                    initials: initials,
                  ),
                  const SizedBox(height: 24),

                  const SectionTitle(title: 'Operación'),
                  SettingsCardGroup(
                    children: [
                      SettingsItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Historial de ventas',
                        subtitle: 'Consulta ventas guardadas y su detalle',
                        onTap: () => context.push('/sales'),
                      ),
                      const GroupDivider(),
                      SettingsItem(
                        icon: Icons.menu_book_outlined,
                        title: 'Libreta de clientes',
                        subtitle: 'Administra clientes, adeudos, cargos y abonos',
                        onTap: () => context.push('/customers'),
                      ),
                      const GroupDivider(),
                      SettingsItem(
                        icon: Icons.inventory_2_outlined,
                        title: 'Productos',
                        subtitle: 'Administra catálogo, stock y códigos',
                        onTap: () => context.push('/products'),
                      ),
                      const GroupDivider(),
                      SettingsItem(
                        icon: Icons.storefront_outlined,
                        title: 'Datos del negocio',
                        subtitle: 'Edita nombre, dirección y datos de la tienda',
                        onTap: () => context.push('/shop'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const SectionTitle(title: 'Hardware'),
                  SettingsCardGroup(
                    children: [
                      SettingsItem(
                        icon: Icons.print_outlined,
                        title: 'Impresora Bluetooth',
                        subtitleWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _printerStatusLabel(printerState),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StatusChip(
                                  label: _printerStatusChipLabel(printerState),
                                  color: _printerStatusColor(printerState),
                                ),
                                if (printerState.connectedMac != null &&
                                    printerState.connectedMac!.trim().isNotEmpty)
                                  InfoChip(
                                    label: printerState.connectedMac!,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailingWidget: PrinterActions(
                          state: printerState,
                          // CAMBIO AQUÍ: 
                          onSearch: () => context.read<PrinterBloc>().add(ScanPrintersEvent()), 
                          onCancelSearch: () => context.read<PrinterBloc>().add(CancelPrinterSearchEvent()), 
                          onDisconnect: () => context.read<PrinterBloc>().add(DisconnectPrinterEvent()), 
                          onForget: () => context.read<PrinterBloc>().add(ForgetPrinterEvent()), 
                          onBluetoothSettings: () => AppSettings.openAppSettings(type: AppSettingsType.bluetooth),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Text(
                      'Para conectar una impresora por primera vez, toca la lupa para buscar dispositivos compatibles cercanos o sincronízala desde los ajustes de tu teléfono.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SectionTitle(title: 'Respaldo'),
                  const SettingsCardGroup(
                    children: [
                      DisabledSettingsItem(
                        icon: Icons.cloud_outlined,
                        title: 'Google Drive',
                        subtitle: 'Aquí aparecerán iniciar sesión, respaldar y restaurar',
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}