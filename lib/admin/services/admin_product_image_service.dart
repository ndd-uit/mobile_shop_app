import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_client.dart';

class AdminProductImageService {
  static const bucket = 'product-images';

  static Future<String> uploadProductImage(XFile file, String productId) async {
    final bytes = await file.readAsBytes();
    final extension = _extensionFor(file.name);
    final path = '$productId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: true,
          ),
        );

    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  static Future<List<String>> uploadProductImages(
    List<XFile> files,
    String productId,
  ) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadProductImage(file, productId));
    }
    return urls;
  }

  static Future<void> deleteProductImageByUrl(String imageUrl) async {
    final path = _pathFromPublicUrl(imageUrl);
    if (path == null) return;
    await supabase.storage.from(bucket).remove([path]);
  }

  static Future<void> deleteProductImagesByUrls(List<String> imageUrls) async {
    final paths = imageUrls
        .map(_pathFromPublicUrl)
        .whereType<String>()
        .toSet()
        .toList();
    if (paths.isEmpty) return;
    await supabase.storage.from(bucket).remove(paths);
  }

  static String? _pathFromPublicUrl(String imageUrl) {
    final marker = '/storage/v1/object/public/$bucket/';
    final markerIndex = imageUrl.indexOf(marker);
    if (markerIndex == -1) return null;
    final path = imageUrl.substring(markerIndex + marker.length).split('?').first;
    return path.isEmpty ? null : Uri.decodeComponent(path);
  }

  static String _extensionFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'png' || extension == 'webp' || extension == 'jpg') {
      return extension;
    }
    return 'jpeg';
  }

  static String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
  }
}
