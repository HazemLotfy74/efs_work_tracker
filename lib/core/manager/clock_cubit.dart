import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The current time for the whole app, updated at the start of every minute.
///
/// Provided once above `MaterialApp` (see main.dart), so it starts with the
/// app and every screen shows the same live time:
///
/// ```dart
/// BlocBuilder<ClockCubit, DateTime>(
///   builder: (context, now) => Text(now.formatTime(context)),
/// )
/// ```
class ClockCubit extends Cubit<DateTime> {
  ClockCubit({DateTime Function() now = DateTime.now})
    : _now = now,
      super(now()) {
    _scheduleNextTick();
    // Timers don't run while the app is in the background; catch up on return.
    _lifecycleListener = AppLifecycleListener(onResume: _tick);
  }

  /// Where the time comes from. Tests pass a fake clock.
  final DateTime Function() _now;
  Timer? _timer;
  late final AppLifecycleListener _lifecycleListener;

  void _tick() {
    if (isClosed) return;
    emit(_now());
    _scheduleNextTick();
  }

  /// Waits until the next minute starts (e.g. 8:07:00), not a fixed 60
  /// seconds, so the app never shows a minute behind the phone's clock.
  void _scheduleNextTick() {
    _timer?.cancel();
    final now = _now();
    // Counted from the seconds, not rebuilt as a local DateTime: a UTC
    // clock would otherwise give a negative delay and re-fire at once.
    final untilNextMinute =
        const Duration(minutes: 1) -
        Duration(
          seconds: now.second,
          milliseconds: now.millisecond,
          microseconds: now.microsecond,
        );
    _timer = Timer(untilNextMinute, _tick);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _lifecycleListener.dispose();
    return super.close();
  }
}
