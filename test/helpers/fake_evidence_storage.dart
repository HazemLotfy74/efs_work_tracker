import 'package:efs_work_tracker/core/services/storage_services.dart';

/// [StorageServices] for admin tests: signs paths, never uploads.
class FakeEvidenceStorage implements StorageServices {
  final signed = <(String bucket, String path, Duration expiresIn)>[];
  Object? signFailure;

  @override
  Future<String> signedUrl({
    required String bucket,
    required String path,
    required Duration expiresIn,
  }) async {
    if (signFailure case final failure?) throw failure;
    signed.add((bucket, path, expiresIn));
    return 'https://storage.test/sign/$bucket/$path?token=t';
  }

  @override
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required String localPath,
    required String contentType,
  }) => throw UnimplementedError('admins never upload evidence');

  @override
  Future<String?> imageTypeOf(String localPath) =>
      throw UnimplementedError('admins never upload evidence');
}
