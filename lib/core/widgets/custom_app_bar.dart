import 'package:flutter/material.dart';

AppBar customAppBar({required BuildContext context,required String title,Widget? leading,Widget? trailing}) {
  return AppBar(
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 50,
    centerTitle: true,
    title: Text(
      title,
      style: TextTheme.of(context).titleMedium!.copyWith(
        color: ColorScheme.of(context).onSurface,
        fontWeight: FontWeight.w900,
      ),
    ),
    leading: leading,
    actions: [
      trailing ?? Container(),
    ],
  );
}
