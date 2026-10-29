abstract class StorageServices {
  /// Uploads the local file at [localPath] to [path] in [bucket].
  ///
  /// Never overwrites. Succeeds without uploading again when [path] already
  /// exists, so a retry after a lost response is safe.
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required String localPath,
    required String contentType,
  });

  /// `jpg`, `png` or `webp` from the file's first bytes, or `null` for any
  /// other content. For paths without an extension, such as the `blob:`
  /// URLs a web browser gives for a photo.
  Future<String?> imageTypeOf(String localPath);
}

/// The image type of [bytes] from its signature (magic number).
String? imageTypeFromBytes(List<int> bytes) {
  bool startsWith(List<int> prefix, [int offset = 0]) {
    if (bytes.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[offset + i] != prefix[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'jpg';
  if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) return 'png';
  // "RIFF" .... "WEBP"
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
      startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return 'webp';
  }
  return null;
}
