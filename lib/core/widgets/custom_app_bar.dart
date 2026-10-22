import 'package:flutter/material.dart';

/// In-page app bar. Colors, elevation and title style come from the theme's
/// `appBarTheme`; only the compact height differs.
AppBar customAppBar({
  required BuildContext context,
  required String title,
  Widget? leading,
  Widget? trailing,
}) {
  return AppBar(
    toolbarHeight: 50,
    title: Text(title),
    leading: leading,
    actions: [trailing ?? Container()],
  );
}
