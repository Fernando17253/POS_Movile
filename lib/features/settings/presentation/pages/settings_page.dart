import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_settings/app_settings.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/printer_bloc.dart';
import '../bloc/printer_event.dart';
import '../bloc/printer_state.dart';

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
    case PrinterStatus.disconnected:
      return 'Sin impresora conectada';

    case PrinterStatus.scanning:
      return 'Buscando impresora...';

    case PrinterStatus.scanSuccess:
      return 'Búsqueda completada';

    case PrinterStatus.scanFailure:
      return 'No se pudo buscar impresoras';

    case PrinterStatus.connecting:
      return 'Conectando...';

    case PrinterStatus.connected:
      return state.connectedName ?? 'Impresora conectada';

    case PrinterStatus.connectionFailure:
      return 'No se pudo conectar a la impresora';

    case PrinterStatus.testPrinting:
      return 'Imprimiendo prueba...';

    case PrinterStatus.error:
      return 'Error de impresora';
  }
}

Color _printerStatusColor(PrinterState state) {
  switch (state.status) {
    case PrinterStatus.connected:
    case PrinterStatus.scanSuccess:
      return Colors.teal;

    case PrinterStatus.scanning:
    case PrinterStatus.connecting:
    case PrinterStatus.testPrinting:
      return Colors.orange;

    case PrinterStatus.scanFailure:
    case PrinterStatus.connectionFailure:
    case PrinterStatus.error:
      return Colors.red;

    case PrinterStatus.initial:
    case PrinterStatus.disconnected:
      return Colors.grey;
  }
}

String _printerStatusChipLabel(PrinterState state) {
  switch (state.status) {
    case PrinterStatus.connected:
      return 'Conectada';

    case PrinterStatus.scanning:
      return 'Buscando';

    case PrinterStatus.scanSuccess:
      return 'Lista';

    case PrinterStatus.scanFailure:
      return 'Fallo de búsqueda';

    case PrinterStatus.connecting:
      return 'Conectando';

    case PrinterStatus.connectionFailure:
      return 'Fallo de conexión';

    case PrinterStatus.testPrinting:
      return 'Imprimiendo';

    case PrinterStatus.error:
      return 'Error';

    case PrinterStatus.initial:
    case PrinterStatus.disconnected:
      return 'Desconectada';
  }
}

  String _buildInitials(String value) {
    final parts = value.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'T';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<PrinterBloc, PrinterState>(
      listenWhen: (previous, current) =>
        previous.status != current.status ||
        previous.errorMessage != current.errorMessage,
        listener: (context, state) {
  if (state.errorMessage != null && state.errorMessage!.trim().isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.errorMessage!),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (state.status == PrinterStatus.connected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impresora conectada correctamente'),
        backgroundColor: Colors.green,
      ),
    );
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _ShopHeaderCard(
                    shopName: shopName,
                    initials: initials,
                  ),
                  const SizedBox(height: 20),

                  _SectionTitle(title: 'Operación'),
                  const SizedBox(height: 10),
_SettingsCardGroup(
  children: [
    _SettingsItem(
      icon: Icons.receipt_long_outlined,
      title: 'Historial de ventas',
      subtitle: 'Consulta ventas guardadas y su detalle',
      onTap: () => context.push('/sales'),
    ),
    _GroupDivider(),
    _SettingsItem(
      icon: Icons.menu_book_outlined,
      title: 'Libreta de clientes',
      subtitle: 'Administra clientes, adeudos, cargos y abonos',
      onTap: () => context.push('/customers'),
    ),
    _GroupDivider(),
    _SettingsItem(
      icon: Icons.inventory_2_outlined,
      title: 'Productos',
      subtitle: 'Administra catálogo, stock y códigos',
      onTap: () => context.push('/products'),
    ),
    _GroupDivider(),
    _SettingsItem(
      icon: Icons.storefront_outlined,
      title: 'Datos del negocio',
      subtitle: 'Edita nombre, dirección y datos de la tienda',
      onTap: () => context.push('/shop'),
    ),
  ],
),

                  const SizedBox(height: 20),

                  _SectionTitle(title: 'Hardware'),
                  const SizedBox(height: 10),
                  _SettingsCardGroup(
                    children: [
                      _SettingsItem(
                        icon: Icons.print_outlined,
                        title: 'Impresora Bluetooth',
                        subtitleWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _printerStatusLabel(printerState),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusChip(
                                  label: _printerStatusChipLabel(printerState),
                                  color: _printerStatusColor(printerState),
                                ),
                                if (printerState.connectedMac != null &&
                                    printerState.connectedMac!.trim().isNotEmpty)
                                  _InfoChip(
                                    label: printerState.connectedMac!,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailingWidget: _PrinterActions(
                          isBusy: printerState.status == PrinterStatus.scanning ||
                              printerState.status == PrinterStatus.connecting,
                          onRefresh: () {
                            context.read<PrinterBloc>().add(RefreshPrinterEvent());
                          },
                          onBluetoothSettings: () {
                            AppSettings.openAppSettings(
                              type: AppSettingsType.bluetooth,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Text(
                      'Para conectar una nueva impresora, primero empareja el dispositivo desde el Bluetooth del teléfono. Luego vuelve aquí y toca actualizar.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _SectionTitle(title: 'Respaldo'),
                  const SizedBox(height: 10),
                  _SettingsCardGroup(
                    children: const [
                      _DisabledSettingsItem(
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

class _ShopHeaderCard extends StatelessWidget {
  final String shopName;
  final String initials;

  const _ShopHeaderCard({
    required this.shopName,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            shopName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configuración general del punto de venta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingsCardGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCardGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[100],
      indent: 68,
      endIndent: 16,
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailingWidget;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailingWidget,
    this.trailingIcon = Icons.chevron_right,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 6),
                    subtitleWidget!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (trailingWidget != null)
              trailingWidget!
            else if (trailingIcon != null)
              Icon(
                trailingIcon,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

class _DisabledSettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DisabledSettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.grey[500],
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.hourglass_top,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

class _PrinterActions extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onRefresh;
  final VoidCallback onBluetoothSettings;

  const _PrinterActions({
    required this.isBusy,
    required this.onRefresh,
    required this.onBluetoothSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBusy)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            color: AppTheme.primaryColor,
          ),
        IconButton(
          onPressed: onBluetoothSettings,
          icon: const Icon(Icons.settings_bluetooth),
          tooltip: 'Bluetooth',
          color: Colors.grey,
        ),
      ],
    );
  }
}