import 'package:flutter/material.dart';

BoxShadow customBoxShadow({
  required double blur,
  required double? x,
  required double? y,
  required Color color,
}) {
  return BoxShadow(
    blurRadius: blur,
    offset: Offset(x ?? 0, y ?? 0),
    color: color, // changes position of shadow
  );
}
