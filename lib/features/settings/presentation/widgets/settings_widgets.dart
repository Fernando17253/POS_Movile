import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/printer_state.dart'; // Importación necesaria para PrinterStatus

class ShopHeaderCard extends StatelessWidget {
  final String shopName;
  final String initials;

  const ShopHeaderCard({
    super.key,
    required this.shopName,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
            width: 96,
            height: 96,
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
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            shopName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configuración general del punto de venta',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.grey[600],
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class SettingsCardGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsCardGroup({super.key, required this.children});

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

class GroupDivider extends StatelessWidget {
  const GroupDivider({super.key});

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

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailingWidget;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
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
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
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
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(trailingIcon, color: Colors.grey[400], size: 28),
              ),
          ],
        ),
      ),
    );
  }
}

class DisabledSettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const DisabledSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.grey[500], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(Icons.hourglass_top, color: Colors.grey[400], size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;

  const InfoChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

// ==========================================
// ACCIONES DE LA IMPRESORA (Dinámicas según estado)
// ==========================================
class PrinterActions extends StatelessWidget {
  final PrinterState state;
  final VoidCallback onSearch;
  final VoidCallback onCancelSearch;
  final VoidCallback onDisconnect;
  final VoidCallback onForget;
  final VoidCallback onBluetoothSettings;

  const PrinterActions({
    super.key,
    required this.state,
    required this.onSearch,
    required this.onCancelSearch,
    required this.onDisconnect,
    required this.onForget,
    required this.onBluetoothSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isScanning = state.status == PrinterStatus.scanning;
    final isConnecting = state.status == PrinterStatus.connecting;
    final isConnected = state.status == PrinterStatus.connected;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isScanning || isConnecting) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          IconButton(
            onPressed: onCancelSearch,
            icon: const Icon(Icons.cancel, size: 28),
            color: Colors.red,
            tooltip: 'Cancelar',
          ),
        ] else if (isConnected) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 28, color: Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'disconnect') onDisconnect();
              if (value == 'forget') onForget();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.link_off, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Desconectar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'forget',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Olvidar dispositivo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search, size: 28),
            tooltip: 'Buscar Impresora',
            color: AppTheme.primaryColor,
          ),
        ],
        IconButton(
          onPressed: onBluetoothSettings,
          icon: const Icon(Icons.settings_bluetooth, size: 28),
          tooltip: 'Ajustes Bluetooth del teléfono',
          color: Colors.grey[600],
        ),
      ],
    );
  }
}

// ==========================================
// VISTA INFERIOR (BOTTOM SHEET) PARA ELEGIR DISPOSITIVO
// ==========================================
class DeviceSelectionBottomSheet extends StatelessWidget {
  // Nota: Usa el tipo de dato real de tu paquete de Bluetooth (ej. BluetoothDevice)
  // Aquí usamos 'dynamic' temporalmente.
  final List<dynamic> devices; 
  final Function(dynamic) onDeviceSelected;

  const DeviceSelectionBottomSheet({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48, height: 6,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.bluetooth_searching, color: theme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Impresoras encontradas',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No se encontraron dispositivos Bluetooth cercanos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  // Aseguramos que Dart sepa que es de tipo BluetoothInfo
                  final device = devices[index];
  
                  // CAMBIO AQUÍ: Usamos macAdress (con una sola 'd', así viene en la librería)
                  final deviceName = device.name.isNotEmpty == true ? device.name : 'Impresora Desconocida';
                  final deviceMac = device.macAdress.isNotEmpty == true ? device.macAdress : 'MAC desconocida';

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onDeviceSelected(device);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.print, size: 32, color: Colors.grey[700]),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(deviceName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(deviceMac, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: theme.primaryColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}