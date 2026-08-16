import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../product/domain/entities/product.dart';
import '../bloc/billing_bloc.dart';
import '../../../../core/theme/app_theme.dart';

// --- Funciones Helper Locales ---
String _formatCurrency(double value) {
  return '\$${value.toStringAsFixed(2)} MXN';
}

String _formatStock(Product product) {
  if (product.stock % 1 == 0) {
    return product.stock.toInt().toString();
  }
  return product.stock.toStringAsFixed(2);
}

String _getUnitLabel(String unitType) {
  const units = {
    'piece': 'pieza',
    'kg': 'kg',
    'g': 'g',
    'lt': 'lt',
    'ml': 'ml',
    'pack': 'paquete',
    'box': 'caja',
  };
  return units[unitType] ?? unitType;
}

// ==========================================
// VISTA DE LISTA (Para teléfonos)
// ==========================================
class ProductListSaleCard extends StatelessWidget {
  final Product product;
  final bool hasStock;

  const ProductListSaleCard({
    super.key,
    required this.product,
    required this.hasStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = hasStock ? Colors.grey.shade300 : Colors.grey.shade200;
    final cardColor = hasStock ? Colors.white : Colors.grey.shade50;
    
    final stockText = hasStock 
        ? '${_formatStock(product)} ${_getUnitLabel(product.unitType)}'
        : 'Sin stock';

    return Opacity(
      opacity: hasStock ? 1 : 0.6,
      child: InkWell(
        onTap: hasStock
            ? () => context.read<BillingBloc>().add(AddProductToCartEvent(product))
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: hasStock ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3)),
            ] : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProductThumbnail(
                imageUrl: product.imageUrl,
                localImagePath: product.localImagePath,
                width: 72, // Imagen un poco más grande
                height: 72,
              ),
              const SizedBox(width: 16),
              // Expanded evita que textos largos rompan la pantalla hacia la derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (product.brand?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // FittedBox ajusta el precio si es un número enorme (ej: $9,999,999.00)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: hasStock ? AppTheme.primaryColor : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stockText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasStock ? Colors.grey[700] : AppTheme.errorColor,
                        fontWeight: hasStock ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                hasStock ? Icons.add_circle : Icons.block,
                color: hasStock ? AppTheme.primaryColor : Colors.grey.shade400,
                size: 32, // Ícono de acción más grande para fácil toque
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// VISTA DE CUADRÍCULA (Para Tablets)
// ==========================================
class ProductSaleCard extends StatelessWidget {
  final Product product;
  final bool hasStock;

  const ProductSaleCard({
    super.key,
    required this.product,
    required this.hasStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockText = hasStock 
        ? '${_formatStock(product)} ${_getUnitLabel(product.unitType)}'
        : 'Sin stock';

    return Opacity(
      opacity: hasStock ? 1 : 0.6,
      child: InkWell(
        onTap: hasStock
            ? () => context.read<BillingBloc>().add(AddProductToCartEvent(product))
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: hasStock ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hasStock ? Colors.grey.shade300 : Colors.grey.shade200),
            boxShadow: hasStock ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 3)),
            ] : [],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumbnail(
                imageUrl: product.imageUrl,
                localImagePath: product.localImagePath,
                height: 100, // Imagen amplia para tablets
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              // Expanded aquí empuja el precio hacia abajo para que todas las tarjetas se vean alineadas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (product.brand?.isNotEmpty ?? false)
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCurrency(product.price),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: hasStock ? AppTheme.primaryColor : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stockText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasStock ? Colors.grey[700] : AppTheme.errorColor,
                  fontWeight: hasStock ? FontWeight.w500 : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// THUMBNAIL (Imagen del producto)
// ==========================================
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double height;
  final double width;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    required this.localImagePath,
    this.height = 56,
    this.width = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (localImagePath != null && localImagePath!.trim().isNotEmpty) {
      final file = File(localImagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, height: height, width: width, fit: BoxFit.cover),
        );
      }
    }

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 32),
    );
  }
}