import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../data/datasources/open_food_facts_remote_datasource.dart';
import '../../../../core/widgets/input_label.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class ProductBarcodeEntryPage extends StatefulWidget {
  const ProductBarcodeEntryPage({super.key});

  @override
  State<ProductBarcodeEntryPage> createState() => _ProductBarcodeEntryPageState();
}

class _ProductBarcodeEntryPageState extends State<ProductBarcodeEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _scanBarcode() async {
    if (_isLoading) return;

    final result = await context.push<String>('/scanner');

    if (result != null && result.isNotEmpty) {
      _barcodeController.text = result;
      setState(() {});
    }
  }

  Future<void> _continueFlow() async {
    if (!_formKey.currentState!.validate()) return;

    final barcode = _barcodeController.text.trim();
    final productState = context.read<ProductBloc>().state;

    Product? existingProduct;
    try {
      existingProduct = productState.products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      existingProduct = null;
    }

    if (existingProduct != null) {
      _showExistingProductDialog(existingProduct);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final datasource = OpenFoodFactsRemoteDatasource();
      final productData = await datasource.findProductByBarcode(barcode);

      if (!mounted) return;

      if (productData != null) {
        context.push(
          '/products/add',
          extra: {
            'barcode': productData['barcode'],
            'internalCode': productData['barcode'],
            'name': productData['name'],
            'brand': productData['brand'],
            'imageUrl': productData['imageUrl'],
            'source': productData['source'],
            'withoutBarcode': false,
          },
        );
      } else {
        context.push(
          '/products/add',
          extra: {
            'barcode': barcode,
            'internalCode': barcode,
            'source': 'manual',
            'withoutBarcode': false,
          },
        );
      }
    } catch (_) {
      if (!mounted) return;

      context.push(
        '/products/add',
        extra: {
          'barcode': barcode,
          'internalCode': barcode,
          'source': 'manual',
          'withoutBarcode': false,
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToManualWithoutBarcode() {
    context.push(
      '/products/add',
      extra: {
        'withoutBarcode': true,
        'source': 'manual',
      },
    );
  }

  void _showExistingProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (innerContext) {
        return AlertDialog(
          title: const Text('Producto ya registrado', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: Text(
            'El código de barras ya pertenece a "${product.name}".',
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(innerContext),
              child: const Text('Cerrar', style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(innerContext);
                context.push(
                  '/products/edit/${product.id}',
                  extra: product,
                );
              },
              child: const Text('Editar producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar producto'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 36, color: theme.primaryColor), // Ícono gigante
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de Información Más Grande y Legible
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo quieres registrar el producto?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Si el producto tiene código de barras, escanéalo o escríbelo.\n\n'
                        '• Si no tiene código, puedes registrarlo manualmente usando el botón de abajo.\n\n'
                        '• Si ya existe en tu catálogo, podrás editarlo.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const InputLabel(text: 'Código de barras'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        keyboardType: TextInputType.number,
                        style: theme.textTheme.titleLarge, // Texto inmenso al escribir el código
                        decoration: const InputDecoration(
                          hintText: 'Escanea o escribe el código',
                        ),
                        validator: AppValidators.required(
                          'Ingresa un código de barras',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Botón de Escáner Gigante
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.barcode_reader,
                          color: AppTheme.primaryColor,
                          size: 36,
                        ),
                        onPressed: _scanBarcode,
                        tooltip: 'Abrir cámara',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Toca el ícono para abrir el escáner y leer el código.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                
                const SizedBox(height: 48),

                // Botón Auxiliar Grande
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _goToManualWithoutBarcode,
                    icon: const Icon(Icons.inventory_2_outlined, size: 28),
                    label: const Text('Agregar producto sin código', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: PrimaryButton(
          onPressed: _isLoading ? null : _continueFlow,
          icon: _isLoading ? Icons.hourglass_top : Icons.arrow_forward_rounded,
          label: _isLoading ? 'Consultando catálogo...' : 'Continuar',
          isLoading: _isLoading,
        ),
      ),
    );
  }
}