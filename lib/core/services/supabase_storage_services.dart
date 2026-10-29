import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/constants.dart';
import 'storage_services.dart';

/// [StorageServices] on Supabase Storage. Throws a [StorageException] or an
/// I/O exception on failure.
///
/// Files are read through [XFile], which works on phones (a file path) and
/// in a web browser (a `blob:` URL), unlike `dart:io` `File`.
class SupabaseStorageServices implements StorageServices {
  @override
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required String localPath,
    required String contentType,
  }) async {
    final bytes = await XFile(localPath).readAsBytes();
    try {
      await Constants.supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
    } on StorageException catch (e) {
      // Already there: an earlier attempt succeeded but its response was lost.
      if (e.statusCode == '409' || e.error == 'Duplicate') return;
      rethrow;
    }
  }

  @override
  Future<String?> imageTypeOf(String localPath) async =>
      imageTypeFromBytes(await XFile(localPath).readAsBytes());
}
