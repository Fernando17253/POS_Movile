import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../bloc/billing_bloc.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/domain/entities/product.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, 
    returnImage: false,
  );
  
  bool _isScanned = false; 
  bool _isContinuousMode = false; 
  
  final Map<String, int> _barcodeConsensus = {};
  final int _requiredConsensusHits = 3; 

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Identificamos si el escáner fue abierto desde la ventana de ventas (POS)
  bool get _isPosMode {
    final extra = GoRouterState.of(context).extra;
    return extra == true; 
  }

  // ALERTA 1: Muestra el producto agregado con éxito
  void _showScannedProductFeedback(Product product) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, 
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95), 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.green.shade700.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                _ProductThumbnail(
                  imageUrl: product.imageUrl,
                  localImagePath: product.localImagePath,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ALERTA 2: Error general (No encontrado, Sin stock, etc.)
  void _showErrorFeedback(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Le damos 1.5 segundos para que alcancen a leer el problema
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final code = barcode.rawValue!;

        _barcodeConsensus[code] = (_barcodeConsensus[code] ?? 0) + 1;

        if (_barcodeConsensus[code]! >= _requiredConsensusHits) {
          _isScanned = true; 
          
          final hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator == true) {
            Vibration.vibrate(duration: 150);
          }

          if (!mounted) return;

          if (_isContinuousMode && _isPosMode) {
            
            // 1. Buscamos el producto en la base de datos local
            final productState = context.read<ProductBloc>().state;
            Product? matchedProduct;
            try {
              matchedProduct = productState.products.firstWhere((p) => p.barcode == code);
            } catch (_) {
              matchedProduct = null;
            }

            if (matchedProduct != null) {
              // 2. Verificamos cuánto stock hay y cuánto ya está en el carrito
              final billingState = context.read<BillingBloc>().state;
              double currentCartQty = 0;
              
              try {
                // Buscamos si ya existe en el carrito
                final itemInCart = billingState.cartItems.firstWhere((i) => i.product.id == matchedProduct!.id);
                currentCartQty = itemInCart.quantity.toDouble(); // Lo pasamos a double por si tienes decimales
              } catch (_) {
                currentCartQty = 0;
              }

              // 3. Lógica de validación
              if (matchedProduct.stock <= 0) {
                // Ya no tiene inventario desde cero
                _showErrorFeedback('Sin stock', 'El producto está agotado en el sistema.');
              } else if (currentCartQty >= matchedProduct.stock) {
                // Ya te acabaste el inventario metiéndolo al carrito
                _showErrorFeedback('Límite alcanzado', 'Sin disponibilidad de productos.');
              } else {
                // Todo está bien, agregamos y mostramos el Gafete verde
                context.read<BillingBloc>().add(ScanBarcodeEvent(code));
                _showScannedProductFeedback(matchedProduct);
              }

            } else {
              // Si el código no está registrado en tu app
              _showErrorFeedback('No encontrado', 'El código escaneado no pertenece a ningún producto.');
            }

            // Pausa antes de volver a escanear
            Timer(const Duration(milliseconds: 1000), () {
              if (mounted) {
                setState(() {
                  _barcodeConsensus.clear(); 
                  _isScanned = false; 
                });
              }
            });
            
          } else {
            // MODO NORMAL 
            context.pop(code);
          }
          break; 
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 36, color: Colors.white), 
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Escanear código',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
            
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(),
              ),
            ),

            Center(
              child: Container(
                height: 250,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: _isScanned && _isContinuousMode ? Colors.green : AppTheme.primaryColor, width: _isScanned && _isContinuousMode ? 6 : 4), 
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    height: 2,
                    width: 260,
                    color: _isScanned && _isContinuousMode ? Colors.transparent : Colors.redAccent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),

            if (_isPosMode)
              Positioned(
                top: 20,
                left: 20,
                right: 80,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    title: const Text('Escaneo Continuo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    subtitle: const Text('No cerrar cámara', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    value: _isContinuousMode,
                    activeColor: AppTheme.primaryColor,
                    inactiveTrackColor: Colors.grey[800],
                    onChanged: (value) => setState(() => _isContinuousMode = value),
                  ),
                ),
              ),

            Positioned(
              top: _isPosMode ? 30 : 20, 
              right: 16,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 28),
                  onPressed: () => controller.toggleTorch(),
                  tooltip: 'Linterna',
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isContinuousMode && _isPosMode
                      ? 'Pasa los productos uno por uno. El cuadro parpadeará.'
                      : 'Alinea el código de barras o QR dentro del marco',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
            ),

            // Pantalla de destello verde general (Solo parpadea si se agregó algo con éxito)
            if (_isScanned && _isContinuousMode && _isPosMode)
              Positioned.fill(
                child: Container(color: Colors.green.withValues(alpha: 0.10)), // Destello más suave
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final screenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 300, height: 250),
        const Radius.circular(20),
      ));
    final finalPath = Path.combine(PathOperation.difference, screenPath, cutoutPath);
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Miniatura para la foto del producto en el popup
class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double height;
  final double width;

  const _ProductThumbnail({
    required this.imageUrl,
    required this.localImagePath,
    this.height = 80,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (localImagePath != null && localImagePath!.trim().isNotEmpty) {
      final file = File(localImagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(file, height: height, width: width, fit: BoxFit.cover),
        );
      }
    }

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 36),
    );
  }
}