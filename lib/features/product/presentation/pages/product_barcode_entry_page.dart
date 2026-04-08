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
  State<ProductBarcodeEntryPage> createState() =>
      _ProductBarcodeEntryPageState();
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
      existingProduct =
          productState.products.firstWhere((p) => p.barcode == barcode);
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
          title: const Text('Producto ya registrado'),
          content: Text(
            'El código de barras ya pertenece a "${product.name}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(innerContext),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(innerContext);
                context.push(
                  '/products/edit/${product.id}',
                  extra: product,
                );
              },
              child: const Text('Editar producto'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar producto'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo quieres registrar el producto?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Si el producto tiene código de barras, escanéalo o escríbelo.\n'
                        '• Si no tiene código, puedes registrarlo manualmente.\n'
                        '• Si ya existe en tu catálogo, podrás editarlo.',
                        style: TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Código de barras'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Escanea o escribe el código',
                        ),
                        validator: AppValidators.required(
                          'Ingresa un código de barras',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.barcode_reader,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: _scanBarcode,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toca el ícono para abrir el escáner y leer el código.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4C669A),
                  ),
                ),
                const SizedBox(height: 24),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _goToManualWithoutBarcode,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Agregar producto sin código de barras'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PrimaryButton(
        onPressed: _isLoading ? null : _continueFlow,
        icon: _isLoading ? Icons.hourglass_top : Icons.arrow_forward_rounded,
        label: _isLoading ? 'Consultando...' : 'Continuar',
      ),
    );
  }
}