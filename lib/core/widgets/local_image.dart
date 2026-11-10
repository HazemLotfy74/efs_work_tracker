import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A photo the user just took. On a phone [path] is a file; in a web
/// browser `image_picker` returns a `blob:` URL instead, which
/// [Image.file] can't open.
///
/// The photo is decoded at the width it is shown at (not the camera's
/// full resolution), which keeps previews light on small phones.
class LocalImage extends StatelessWidget {
  const LocalImage(this.path, {super.key, this.fit, this.width, this.height});

  final String path;
  final BoxFit? fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shown = width ?? constraints.maxWidth;
        final decodeWidth = shown.isFinite
            ? (shown * MediaQuery.devicePixelRatioOf(context)).round()
            : null;
        return kIsWeb
            ? Image.network(
                path,
                fit: fit,
                width: width,
                height: height,
                cacheWidth: decodeWidth,
              )
            : Image.file(
                File(path),
                fit: fit,
                width: width,
                height: height,
                cacheWidth: decodeWidth,
              );
      },
    );
  }
}
