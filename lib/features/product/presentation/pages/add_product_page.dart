import 'dart:io';

import 'package:billing_app/core/services/product_image_service.dart';
import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/app_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';

class AddProductPage extends StatefulWidget {
  final String? initialBarcode;
  final String? initialInternalCode;
  final String? initialName;
  final String? initialBrand;
  final String? initialImageUrl;
  final String source;
  final bool withoutBarcode;

  const AddProductPage({
    super.key,
    this.initialBarcode,
    this.initialInternalCode,
    this.initialName,
    this.initialBrand,
    this.initialImageUrl,
    this.source = 'manual',
    this.withoutBarcode = false,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
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
  String _selectedUnitType = 'piece';
  bool _isWeighable = false;

  File? _selectedImageFile;
  bool _removeDetectedImage = false;
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

    _withoutBarcode = widget.withoutBarcode;

    _barcodeController = TextEditingController(text: widget.initialBarcode ?? '');
    _internalCodeController = TextEditingController(text: widget.initialInternalCode ?? '');
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

      if (_internalCodeController.text.trim().isEmpty) {
        _internalCodeController.text = result;
      }

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

  String _generateInternalCode({required String name, String? barcode, String? manualCode}) {
    final sanitizedManual = _sanitizeInternalCode(manualCode ?? '');
    if (sanitizedManual.isNotEmpty) return sanitizedManual;

    final sanitizedBarcode = _sanitizeInternalCode(barcode ?? '');
    if (sanitizedBarcode.isNotEmpty) return sanitizedBarcode;

    final sanitizedName = _sanitizeInternalCode(name);
    if (sanitizedName.isNotEmpty) {
      final shortName = sanitizedName.length > 12 ? sanitizedName.substring(0, 12) : sanitizedName;
      final suffix = const Uuid().v4().substring(0, 4).toUpperCase();
      return '$shortName-$suffix';
    }

    final suffix = const Uuid().v4().substring(0, 8).toUpperCase();
    return 'PROD-$suffix';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontSize: 16)), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 90);
      if (pickedFile == null) return;

      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _removeDetectedImage = false;
      });
    } catch (_) {
      _showError('No se pudo seleccionar la imagen.');
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white, // Fondo blanco sólido para que las opciones sean legibles
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        final hasAnyImage = _selectedImageFile != null || (!_removeDetectedImage && widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty);

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
                        _removeDetectedImage = true;
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

    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final price = _parseDouble(_priceController.text);
    final cost = _parseDouble(_costController.text);
    final stock = _parseDouble(_stockController.text);
    final minStock = _parseDouble(_minStockController.text);

    final internalCode = _generateInternalCode(name: name, barcode: barcode, manualCode: _internalCodeController.text);
    final productState = context.read<ProductBloc>().state;

    if (barcode != null) {
      final duplicatedBarcode = productState.products.any((p) => p.barcode == barcode);
      if (duplicatedBarcode) {
        _showError('Ya existe un producto con este código de barras.');
        return;
      }
    }

    final duplicatedInternalCode = productState.products.any((p) => p.internalCode.toUpperCase() == internalCode.toUpperCase());
    if (duplicatedInternalCode) {
      _showError('Ya existe un producto con ese identificador interno.');
      return;
    }

    setState(() => _isSavingImage = true);

    final productId = const Uuid().v4();
    String? localImagePath;
    String? finalImageUrl;

    if (_selectedImageFile != null) {
      localImagePath = await ProductImageService().saveFileImageLocally(sourceFile: _selectedImageFile!, productId: productId);
      finalImageUrl = null;
    } else if (!_removeDetectedImage && widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      localImagePath = await ProductImageService().saveNetworkImageLocally(imageUrl: widget.initialImageUrl!, productId: productId);
      finalImageUrl = widget.initialImageUrl;
    } else {
      localImagePath = null;
      finalImageUrl = null;
    }

    if (!mounted) return;

    final product = Product(
      id: productId,
      internalCode: internalCode,
      name: name,
      barcode: barcode,
      brand: brand.isEmpty ? null : brand,
      imageUrl: finalImageUrl,
      localImagePath: localImagePath,
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

    setState(() => _isSavingImage = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromApi = widget.source == 'open_food_facts';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar producto'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 36, color: theme.primaryColor),
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
                if (fromApi) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Se detectaron datos del producto. Completa la información faltante antes de guardarlo.',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sin código de barras', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('Actívalo para productos elaborados, frutas o productos sueltos.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
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

                // --- PRECIOS Y STOCK ---
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
                            style: theme.textTheme.displayMedium?.copyWith(fontSize: 26, color: AppTheme.primaryColor),
                            validator: (value) => _requiredNumberValidator(value, 'Ingresa el precio'),
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
                            validator: (value) => _requiredNumberValidator(value, 'Ingresa el costo'),
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
                          const InputLabel(text: 'Stock inicial'),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            validator: (value) => _requiredNumberValidator(value, 'Ingresa el stock'),
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
                            validator: (value) => _requiredNumberValidator(value, 'Ingresa stock mín.'),
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
                  items: _unitOptions.map((unit) => DropdownMenuItem<String>(
                    value: unit['value'],
                    child: Text(unit['label']!),
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
                        : (!_removeDetectedImage && widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  widget.initialImageUrl!,
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
                        label: const Text('Agregar o cambiar', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                    ),
                    if (_selectedImageFile != null || (!_removeDetectedImage && widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty)) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedImageFile = null;
                              _removeDetectedImage = true;
                            });
                          },
                          icon: const Icon(Icons.delete_outline, size: 24, color: Colors.red),
                          label: const Text('Quitar imagen', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
          icon: _isSavingImage ? Icons.hourglass_top : Icons.add_circle,
          label: _isSavingImage ? 'Guardando imagen...' : 'Guardar producto',
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