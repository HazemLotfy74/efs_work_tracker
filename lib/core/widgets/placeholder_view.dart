import 'package:flutter/material.dart';

/// Temporary screen used by the router until the real view is built.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
