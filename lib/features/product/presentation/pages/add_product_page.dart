import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class AddProductPage extends StatefulWidget {
  final String? initialBarcode;
  final String? initialName;
  final String? initialBrand;
  final String? initialImageUrl;
  final String source;

  const AddProductPage({
    super.key,
    this.initialBarcode,
    this.initialName,
    this.initialBrand,
    this.initialImageUrl,
    this.source = 'manual',
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;

  String _selectedUnitType = 'piece';
  bool _isWeighable = false;

  static const List<Map<String, String>> _unitOptions = [
    {'value': 'piece', 'label': 'Pieza'},
    {'value': 'kg', 'label': 'Kilogramo (kg)'},
    {'value': 'g', 'label': 'Gramo (g)'},
    {'value': 'lt', 'label': 'Litro (lt)'},
    {'value': 'ml', 'label': 'Mililitro (ml)'},
    {'value': 'pack', 'label': 'Paquete'},
    {'value': 'box', 'label': 'Caja'},
  ];

  @override
  void initState() {
    super.initState();

    _barcodeController = TextEditingController(text: widget.initialBarcode ?? '');
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _brandController = TextEditingController(text: widget.initialBrand ?? '');
    _priceController = TextEditingController();
    _costController = TextEditingController();
    _stockController = TextEditingController();
    _minStockController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');

    if (result != null && result.isNotEmpty) {
      _barcodeController.text = result;
      setState(() {});
    }
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String? _requiredNumberValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return 'Ingresa un número válido';
    }

    if (parsed < 0) {
      return 'El valor no puede ser negativo';
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final price = _parseDouble(_priceController.text);
    final cost = _parseDouble(_costController.text);
    final stock = _parseDouble(_stockController.text);
    final minStock = _parseDouble(_minStockController.text);

    final productState = context.read<ProductBloc>().state;

    Product? existingProduct;
    try {
      existingProduct =
          productState.products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      existingProduct = null;
    }

    if (existingProduct != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un producto con este código de barras.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final product = Product(
      id: const Uuid().v4(),
      name: name,
      barcode: barcode,
      brand: brand.isEmpty ? null : brand,
      imageUrl: widget.initialImageUrl,
      categoryId: null,
      price: price,
      cost: cost,
      stock: stock,
      minStock: minStock,
      unitType: _selectedUnitType,
      isWeighable: _isWeighable,
      source: widget.source,
    );

    context.read<ProductBloc>().add(AddProduct(product));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final fromApi = widget.source == 'open_food_facts';

    return Scaffold(
      appBar: AppBar(
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
        title: const Text(
          'Agregar producto',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
                if (fromApi) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Text(
                      'Se detectaron datos del producto. Completa la información faltante antes de guardarlo.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                const InputLabel(text: 'Código de barras'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
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
                          Icons.qr_code_scanner,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: _scanBarcode,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Toca el ícono para abrir el escáner.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4C669A)),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Nombre del producto'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Arroz, Coca-Cola, Sabritas',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.required(
                    'Ingresa el nombre del producto',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Marca (opcional)'),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Coca-Cola, Sabritas',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Precio de venta'),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixText: '\$ ',
                  ),
                  validator: (value) => _requiredNumberValidator(
                    value,
                    'Ingresa el precio de venta',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Costo de compra'),
                TextFormField(
                  controller: _costController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixText: '\$ ',
                  ),
                  validator: (value) => _requiredNumberValidator(
                    value,
                    'Ingresa el costo de compra',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Stock inicial'),
                TextFormField(
                  controller: _stockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0',
                  ),
                  validator: (value) => _requiredNumberValidator(
                    value,
                    'Ingresa el stock inicial',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Stock mínimo'),
                TextFormField(
                  controller: _minStockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0',
                  ),
                  validator: (value) => _requiredNumberValidator(
                    value,
                    'Ingresa el stock mínimo',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Unidad de venta'),
                DropdownButtonFormField<String>(
                  value: _selectedUnitType,
                  items: _unitOptions
                      .map(
                        (unit) => DropdownMenuItem<String>(
                          value: unit['value'],
                          child: Text(unit['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedUnitType = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Selecciona una unidad',
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Producto pesable'),
                  subtitle: const Text(
                    'Actívalo para productos que se venden por peso.',
                  ),
                  value: _isWeighable,
                  onChanged: (value) {
                    setState(() {
                      _isWeighable = value;
                    });
                  },
                ),

                if (widget.initialImageUrl != null &&
                    widget.initialImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const InputLabel(text: 'Imagen detectada'),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      widget.initialImageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text('No se pudo cargar la imagen'),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PrimaryButton(
        onPressed: _submit,
        icon: Icons.add_circle,
        label: 'Guardar producto',
      ),
    );
  }
}