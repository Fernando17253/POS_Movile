import 'dart:io';

import 'package:billing_app/core/services/product_image_service.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/app_validators.dart';
import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

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

  File? _selectedImageFile;
  late String? _existingLocalImagePath;
  late String? _existingImageUrl;
  bool _removeImage = false;
  bool _isSavingImage = false;

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

    _withoutBarcode = widget.product.barcode == null || widget.product.barcode!.trim().isEmpty;
    _selectedUnitType = widget.product.unitType;
    _isWeighable = widget.product.isWeighable;

    _existingLocalImagePath = widget.product.localImagePath;
    _existingImageUrl = widget.product.imageUrl;

    _barcodeController = TextEditingController(text: widget.product.barcode ?? '');
    _internalCodeController = TextEditingController(text: widget.product.internalCode);
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _costController = TextEditingController(text: widget.product.cost.toStringAsFixed(2));
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _minStockController = TextEditingController(text: widget.product.minStock.toString());
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

  void _scanBarcode() async {
    if (_withoutBarcode) return;

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
    if (value == null || value.trim().isEmpty) return message;
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) return 'Ingresa un número válido';
    if (parsed < 0) return 'El valor no puede ser negativo';
    return null;
  }

  String _sanitizeInternalCode(String value) {
    return value.trim().toUpperCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^A-Z0-9\-_]'), '');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontSize: 16)), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 90);
      if (pickedFile == null) return;

      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _removeImage = false;
      });
    } catch (_) {
      _showError('No se pudo seleccionar la imagen.');
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white, // Fondo blanco sólido garantizado
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        final hasAnyImage = _selectedImageFile != null ||
            (!_removeImage && ((_existingLocalImagePath != null && _existingLocalImagePath!.isNotEmpty) ||
                    (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, size: 32),
                  title: const Text('Tomar foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, size: 32),
                  title: const Text('Elegir de galería', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (hasAnyImage) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
                    title: const Text('Quitar imagen', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _selectedImageFile = null;
                        _removeImage = true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final rawBarcode = _barcodeController.text.trim();
    final barcode = _withoutBarcode || rawBarcode.isEmpty ? null : rawBarcode;
    final internalCode = _sanitizeInternalCode(_internalCodeController.text);

    if (internalCode.isEmpty) {
      _showError('Ingresa un identificador interno válido.');
      return;
    }

    final productState = context.read<ProductBloc>().state;

    if (barcode != null && productState.products.any((p) => p.id != widget.product.id && p.barcode == barcode)) {
      _showError('Ya existe otro producto con este código de barras.');
      return;
    }

    if (productState.products.any((p) => p.id != widget.product.id && p.internalCode.toUpperCase() == internalCode.toUpperCase())) {
      _showError('Ya existe otro producto con ese identificador interno.');
      return;
    }

    setState(() => _isSavingImage = true);

    String? finalLocalImagePath = _existingLocalImagePath;
    String? finalImageUrl = _existingImageUrl;

    if (_removeImage) {
      await ProductImageService().deleteLocalImage(_existingLocalImagePath);
      finalLocalImagePath = null;
      finalImageUrl = null;
    } else if (_selectedImageFile != null) {
      await ProductImageService().deleteLocalImage(_existingLocalImagePath);
      finalLocalImagePath = await ProductImageService().saveFileImageLocally(sourceFile: _selectedImageFile!, productId: widget.product.id);
      finalImageUrl = null;
    }

    if (!mounted) return;

    final updatedProduct = Product(
      id: widget.product.id,
      internalCode: internalCode,
      name: _nameController.text.trim(),
      barcode: barcode,
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      imageUrl: finalImageUrl,
      localImagePath: finalLocalImagePath,
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

    setState(() => _isSavingImage = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final hasLocalImage = !_removeImage && _existingLocalImagePath != null && _existingLocalImagePath!.isNotEmpty && File(_existingLocalImagePath!).existsSync();
    final hasNetworkImage = !_removeImage && _existingImageUrl != null && _existingImageUrl!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar producto'),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Producto sin código de barras', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('Actívalo para frutas, verduras o productos sueltos.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  value: _withoutBarcode,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _withoutBarcode = value;
                      if (value) _barcodeController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (!_withoutBarcode) ...[
                  const InputLabel(text: 'Código de barras'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.titleLarge, // Texto enorme para el código
                          decoration: const InputDecoration(hintText: 'Escanea o escribe el código'),
                          validator: _withoutBarcode ? null : AppValidators.required('Ingresa un código de barras'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                        child: IconButton(
                          icon: const Icon(Icons.barcode_reader, color: AppTheme.primaryColor, size: 36),
                          onPressed: _scanBarcode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Toca el ícono para escanear usando la cámara.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                ],

                const InputLabel(text: 'Identificador interno'),
                TextFormField(
                  controller: _internalCodeController,
                  style: theme.textTheme.titleMedium,
                  decoration: const InputDecoration(hintText: 'Ej. QUESO-OAX, PROD-001'),
                  validator: AppValidators.required('Ingresa el identificador interno'),
                ),
                const SizedBox(height: 8),
                Text('Si lo dejas vacío, el sistema lo generará automáticamente.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 24),

                const InputLabel(text: 'Nombre del producto'),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: theme.textTheme.titleMedium,
                  validator: AppValidators.required('Ingresa el nombre del producto'),
                  decoration: const InputDecoration(hintText: 'Ej. Jitomate, Queso Oaxaca, Coca-Cola'),
                ),
                const SizedBox(height: 24),

                const InputLabel(text: 'Marca (opcional)'),
                TextFormField(
                  controller: _brandController,
                  textCapitalization: TextCapitalization.words,
                  style: theme.textTheme.titleMedium,
                  decoration: const InputDecoration(hintText: 'Ej. Coca-Cola, Sabritas'),
                ),
                const SizedBox(height: 32),

                // --- SECCIÓN DE PRECIOS Y STOCK (NÚMEROS GIGANTES) ---
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const InputLabel(text: 'Precio de venta'),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: theme.textTheme.displayMedium?.copyWith(fontSize: 26, color: AppTheme.primaryColor), // Números gigantes
                            validator: (v) => _requiredNumberValidator(v, 'Ingresa el precio'),
                            decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const InputLabel(text: 'Costo de compra'),
                          TextFormField(
                            controller: _costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: theme.textTheme.displayMedium?.copyWith(fontSize: 26),
                            validator: (v) => _requiredNumberValidator(v, 'Ingresa el costo'),
                            decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const InputLabel(text: 'Stock actual'),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            validator: (v) => _requiredNumberValidator(v, 'Ingresa el stock'),
                            decoration: const InputDecoration(hintText: '0'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const InputLabel(text: 'Stock mínimo'),
                          TextFormField(
                            controller: _minStockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            validator: (v) => _requiredNumberValidator(v, 'Ingresa stock mín.'),
                            decoration: const InputDecoration(hintText: '0'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- LÓGICA INTELIGENTE DE UNIDADES ---
                const InputLabel(text: 'Unidad de venta'),
                DropdownButtonFormField<String>(
                  value: _selectedUnitType,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                  style: theme.textTheme.titleMedium,
                  items: _unitOptions.map((u) => DropdownMenuItem<String>(
                    value: u['value'],
                    child: Text(u['label']!),
                  )).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedUnitType = value;
                      // LÓGICA INTELIGENTE: Autoselección de decimales
                      if (['kg', 'g', 'lt', 'ml'].contains(value)) {
                        _isWeighable = true; // Activa decimales
                      } else {
                        _isWeighable = false; // Desactiva decimales
                      }
                    });
                  },
                  decoration: const InputDecoration(hintText: 'Selecciona una unidad'),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Venta a granel (Permite decimales)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('Actívalo si vas a vender fracciones de este producto (ej. 1.5 kg, 0.5 litros o media caja).', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  value: _isWeighable,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) => setState(() => _isWeighable = value),
                ),
                const SizedBox(height: 24),

                // --- SECCIÓN IMAGEN ---
                const InputLabel(text: 'Imagen del producto'),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showImageSourceSheet,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: _selectedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                          )
                        : hasLocalImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(File(_existingLocalImagePath!), fit: BoxFit.cover),
                              )
                            : hasNetworkImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _existingImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                                    ),
                                  )
                                : const _ImagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showImageSourceSheet,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 24),
                        label: const Text('Cambiar imagen', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    if (_selectedImageFile != null || hasLocalImage || hasNetworkImage) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedImageFile = null;
                              _removeImage = true;
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 24, color: Colors.red),
                          label: const Text('Quitar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: PrimaryButton(
          onPressed: _isSavingImage ? null : _submit,
          icon: _isSavingImage ? Icons.hourglass_top : Icons.save,
          label: _isSavingImage ? 'Guardando cambios...' : 'Guardar Cambios',
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Sin imagen',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca para agregar una foto',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}