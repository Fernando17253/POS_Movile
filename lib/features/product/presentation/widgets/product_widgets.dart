import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/product.dart';

// ==========================================
// TARJETA DE PRODUCTO EXTRA GRANDE (LISTA)
// ==========================================
class ProductManagementCard extends StatelessWidget {
  final Product product;
  final String currencyText;
  final String stockText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestock; // NUEVO: Reabastecimiento
  final VoidCallback onWaste;   // NUEVO: Merma/Pérdida

  const ProductManagementCard({
    super.key,
    required this.product,
    required this.currencyText,
    required this.stockText,
    required this.onEdit,
    required this.onDelete,
    required this.onRestock,
    required this.onWaste,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBarcode = product.barcode != null && product.barcode!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Bordes redondeados
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
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProductThumbnail(
                  imageUrl: product.imageUrl,
                  localImagePath: product.localImagePath,
                  width: 78,
                  height: 78,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (product.brand?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(
                          product.brand!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _InfoBadge(
                            label: currencyText,
                            textColor: AppTheme.primaryColor,
                            bgColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                          _InfoBadge(
                            label: stockText,
                            textColor: Colors.grey.shade900,
                            bgColor: Colors.grey.shade200,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Clave: ${product.internalCode}',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasBarcode ? 'Código: ${product.barcode}' : 'Sin código de barras',
                        style: TextStyle(
                          fontSize: 14,
                          color: hasBarcode ? Colors.grey[600] : Colors.orange[800],
                          fontWeight: hasBarcode ? FontWeight.bold : FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Barra de acciones inferiores para Reabastecer, Merma, Editar y Eliminar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onRestock,
                    icon: const Icon(Icons.add_box, color: Colors.green),
                    label: const Text('Surtir', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onWaste,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                    label: const Text('Merma', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                  tooltip: 'Editar producto',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Eliminar producto',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mini-componente interno para los tags de precio y stock
class _InfoBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _InfoBadge({required this.label, required this.textColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15), 
      ),
    );
  }
}

// ==========================================
// MINIATURA DEL PRODUCTO
// ==========================================
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double width;
  final double height;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    required this.localImagePath,
    this.width = 86,
    this.height = 86,
  });

  @override
  Widget build(BuildContext context) {
    if (localImagePath != null && localImagePath!.trim().isNotEmpty) {
      final file = File(localImagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(file, width: width, height: height, fit: BoxFit.cover),
        );
      }
    }

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl!, width: width, height: height, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: width * 0.5),
    );
  }
}

// ==========================================
// ESTADO VACÍO (EMPTY STATE)
// ==========================================
class EmptyProductsState extends StatelessWidget {
  final bool hasSearch;

  const EmptyProductsState({super.key, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off_outlined : Icons.inventory_2_outlined,
              size: 80, color: Colors.grey[400], 
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch ? 'No hay productos que coincidan' : 'Aún no hay productos registrados',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? 'Prueba buscar con otra palabra, marca o código de barras.'
                  : 'Agrega tu primer producto al catálogo para comenzar a vender.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}