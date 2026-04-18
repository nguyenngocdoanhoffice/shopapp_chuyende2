import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../supabase_client.dart';

class StorageService {
  static const _bucket = 'product-images';

  Future<String> uploadProductImage(XFile file) async {
    try {
      final bytes = await File(file.path).readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await supabase.storage.from(_bucket).uploadBinary(fileName, bytes);

      final publicUrl = supabase.storage.from(_bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
