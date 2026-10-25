import 'dart:async';

import 'package:flutter/material.dart';

import '../extensions/duration_format.dart';

/// Counts up from [since] every second, e.g. 03:26:18.
///
/// Has its own one-second timer, so only this text rebuilds, not the screen.
class ElapsedTimeText extends StatefulWidget {
  const ElapsedTimeText({super.key, required this.since, this.style});

  final DateTime since;
  final TextStyle? style;

  @override
  State<ElapsedTimeText> createState() => _ElapsedTimeTextState();
}

class _ElapsedTimeTextState extends State<ElapsedTimeText> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateTime.now().difference(widget.since).formatStopwatch(),
      style: widget.style,
    );
  }
}
