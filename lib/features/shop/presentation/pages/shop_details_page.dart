import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/shop.dart';
import '../bloc/shop_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _phoneController;
  late TextEditingController _upiController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _address1Controller = TextEditingController();
    _address2Controller = TextEditingController();
    _phoneController = TextEditingController();
    _upiController = TextEditingController();
    _footerController = TextEditingController();

    // Load shop data
    context.read<ShopBloc>().add(LoadShopEvent());
  }

  void _updateControllers(Shop shop) {
    if (_nameController.text.isEmpty && shop.name.isNotEmpty) {
      _nameController.text = shop.name;
      _address1Controller.text = shop.addressLine1;
      _address2Controller.text = shop.addressLine2;
      _phoneController.text = shop.phoneNumber;
      _upiController.text = shop.upiId;
      _footerController.text = shop.footerText;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveShop() {
    if (_formKey.currentState!.validate()) {
      final shop = Shop(
        name: _nameController.text.trim(),
        addressLine1: _address1Controller.text.trim(),
        addressLine2: _address2Controller.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        upiId: _upiController.text.trim(),
        footerText: _footerController.text.trim(),
      );

      context.read<ShopBloc>().add(UpdateShopEvent(shop));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del negocio'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 36, color: theme.primaryColor), // Ícono gigante
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<ShopBloc, ShopState>(
        listener: (context, state) {
          if (state is ShopLoaded) {
            _updateControllers(state.shop);
          } else if (state is ShopOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Datos guardados correctamente!', style: TextStyle(fontSize: 16)),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is ShopError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: const TextStyle(fontSize: 16)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        buildWhen: (previous, current) => current is ShopLoading || current is ShopLoaded,
        builder: (context, state) {
          if (state is ShopLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta de información destacada
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 42, color: AppTheme.primaryColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información Pública',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Estos datos aparecerán en el encabezado y pie de tus tickets impresos.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const InputLabel(text: 'Nombre del negocio'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Ej. Abarrotes San Juan',
                      validator: AppValidators.required('Ingresa el nombre del negocio'),
                      textStyle: theme.textTheme.titleLarge, // Texto masivo
                    ),
                    const SizedBox(height: 24),

                    const InputLabel(text: 'Dirección principal'),
                    _buildTextField(
                      controller: _address1Controller,
                      hint: 'Ej. Calle Benito Juárez #123',
                      validator: AppValidators.required('Ingresa la dirección principal'),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),

                    const InputLabel(text: 'Colonia / Código Postal (Opcional)'),
                    _buildTextField(
                      controller: _address2Controller,
                      hint: 'Ej. Col. Centro, CP 30540',
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),

                    const InputLabel(text: 'Teléfono'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Ej. 918 123 4567',
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.required('Ingresa un teléfono válido'),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),

                    const InputLabel(text: 'Datos de transferencia o pago (Opcional)'),
                    _buildTextField(
                      controller: _upiController,
                      hint: 'Ej. Cuenta BBVA / CLABE: 01234567890',
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const InputLabel(text: 'Mensaje final del ticket'),
                        Text(
                          'Máx. 60 caracteres',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _footerController,
                      hint: 'Ej. ¡Gracias por su compra, vuelva pronto!',
                      maxLines: 2,
                      maxLength: 60,
                      textStyle: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Botón protegido con SafeArea nativo
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: PrimaryButton(
          onPressed: _saveShop,
          icon: Icons.save,
          label: 'Guardar Cambios',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    TextStyle? textStyle,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.words,
      validator: validator,
      style: textStyle,
      decoration: InputDecoration(
        hintText: hint,
      ),
    );
  }
}