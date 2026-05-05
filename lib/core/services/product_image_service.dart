import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ProductImageService {
  Future<Directory> _getImagesDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final imagesDir = Directory('${baseDir.path}/product_images');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  Future<String?> saveNetworkImageLocally({
    required String imageUrl,
    required String productId,
  }) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      return await _compressAndSaveBytes(
        bytes: response.bodyBytes,
        productId: productId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> saveFileImageLocally({
    required File sourceFile,
    required String productId,
  }) async {
    try {
      final bytes = await sourceFile.readAsBytes();
      return await _compressAndSaveBytes(
        bytes: bytes,
        productId: productId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _compressAndSaveBytes({
    required Uint8List bytes,
    required String productId,
  }) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final targetPath = '${imagesDir.path}/product_$productId.jpg';

      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 75,
        minWidth: 1000,
        minHeight: 1000,
        format: CompressFormat.jpeg,
      );

      final file = File(targetPath);
      await file.writeAsBytes(compressedBytes, flush: true);

      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteLocalImage(String? path) async {
    if (path == null || path.trim().isEmpty) return;

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}