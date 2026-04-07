import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsRemoteDatasource {
  static const _baseUrl = 'https://world.openfoodfacts.org';

  Future<Map<String, dynamic>?> findProductByBarcode(String barcode) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v2/product/$barcode?fields=code,product_name,brands,image_front_url,quantity',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'AbarrotesPOS/1.0 (contacto@tuapp.local)',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar Open Food Facts');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final status = data['status'] as int? ?? 0;
    if (status != 1) return null;

    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    return {
      'barcode': data['code']?.toString() ?? barcode,
      'name': product['product_name']?.toString(),
      'brand': product['brands']?.toString(),
      'imageUrl': product['image_front_url']?.toString(),
      'quantityText': product['quantity']?.toString(),
      'source': 'open_food_facts',
    };
  }
}