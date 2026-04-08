import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({
    super.key,
    required this.product,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _barcodeController;
  late final TextEditingController _internalCodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;

  late bool _withoutBarcode;
  late String _selectedUnitType;
  late bool _isWeighable;

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

    _withoutBarcode =
        widget.product.barcode == null || widget.product.barcode!.trim().isEmpty;
    _selectedUnitType = widget.product.unitType;
    _isWeighable = widget.product.isWeighable;

    _barcodeController =
        TextEditingController(text: widget.product.barcode ?? '');
    _internalCodeController =
        TextEditingController(text: widget.product.internalCode);
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _priceController =
        TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _costController =
        TextEditingController(text: widget.product.cost.toStringAsFixed(2));
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
    _minStockController =
        TextEditingController(text: widget.product.minStock.toString());
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _internalCodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String? _requiredNumberValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) return 'Ingresa un número válido';
    if (parsed < 0) return 'El valor no puede ser negativo';

    return null;
  }

  String _sanitizeInternalCode(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^A-Z0-9\-_]'), '');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final rawBarcode = _barcodeController.text.trim();
    final barcode = _withoutBarcode || rawBarcode.isEmpty ? null : rawBarcode;
    final internalCode = _sanitizeInternalCode(_internalCodeController.text);

    if (internalCode.isEmpty) {
      _showError('Ingresa un identificador interno válido.');
      return;
    }

    final productState = context.read<ProductBloc>().state;

    if (barcode != null &&
        productState.products.any(
          (p) => p.id != widget.product.id && p.barcode == barcode,
        )) {
      _showError('Ya existe otro producto con este código de barras.');
      return;
    }

    if (productState.products.any(
      (p) =>
          p.id != widget.product.id &&
          p.internalCode.toUpperCase() == internalCode.toUpperCase(),
    )) {
      _showError('Ya existe otro producto con ese identificador interno.');
      return;
    }

    final updatedProduct = Product(
      id: widget.product.id,
      internalCode: internalCode,
      name: _nameController.text.trim(),
      barcode: barcode,
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      imageUrl: widget.product.imageUrl,
      categoryId: widget.product.categoryId,
      price: _parseDouble(_priceController.text),
      cost: _parseDouble(_costController.text),
      stock: _parseDouble(_stockController.text),
      minStock: _parseDouble(_minStockController.text),
      unitType: _selectedUnitType,
      isWeighable: _isWeighable,
      source: widget.product.source,
    );

    context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.product.imageUrl != null &&
        widget.product.imageUrl!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 32,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Editar producto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_withoutBarcode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.barcode_reader,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CÓDIGO DE BARRAS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.product.barcode ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Producto sin código de barras'),
                  subtitle: const Text(
                    'Actívalo para frutas, verduras, queso u otros productos sin código.',
                  ),
                  value: _withoutBarcode,
                  onChanged: (value) {
                    setState(() {
                      _withoutBarcode = value;
                      if (value) {
                        _barcodeController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (!_withoutBarcode) ...[
                  const InputLabel(text: 'Código de barras'),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe el código de barras',
                    ),
                    validator: _withoutBarcode
                        ? null
                        : AppValidators.required(
                            'Ingresa un código de barras',
                          ),
                  ),
                  const SizedBox(height: 24),
                ],

                const InputLabel(text: 'Identificador interno'),
                TextFormField(
                  controller: _internalCodeController,
                  decoration: const InputDecoration(
                    hintText: 'Ej. QUESO-OAX, JITOMATE-KG o PROD-001',
                  ),
                  validator: AppValidators.required(
                    'Ingresa el identificador interno',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Nombre del producto'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Jitomate, Queso Oaxaca, Coca-Cola',
                  ),
                  validator: AppValidators.required(
                    'Ingresa el nombre del producto',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Marca (opcional)'),
                TextFormField(
                  controller: _brandController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Coca-Cola, Sabritas',
                  ),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Precio de venta'),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  validator: (v) =>
                      _requiredNumberValidator(v, 'Ingresa el precio de venta'),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Costo de compra'),
                TextFormField(
                  controller: _costController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  validator: (v) =>
                      _requiredNumberValidator(v, 'Ingresa el costo de compra'),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Stock actual'),
                TextFormField(
                  controller: _stockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0',
                  ),
                  validator: (v) =>
                      _requiredNumberValidator(v, 'Ingresa el stock actual'),
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
                  validator: (v) =>
                      _requiredNumberValidator(v, 'Ingresa el stock mínimo'),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Unidad de venta'),
                DropdownButtonFormField<String>(
                  value: _selectedUnitType,
                  items: _unitOptions
                      .map(
                        (u) => DropdownMenuItem<String>(
                          value: u['value'],
                          child: Text(u['label']!),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedUnitType = v;
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

                if (hasImage) ...[
                  const SizedBox(height: 16),
                  const InputLabel(text: 'Imagen del producto'),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      widget.product.imageUrl!,
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
        icon: Icons.save,
        label: 'Guardar cambios',
      ),
    );
  }
}