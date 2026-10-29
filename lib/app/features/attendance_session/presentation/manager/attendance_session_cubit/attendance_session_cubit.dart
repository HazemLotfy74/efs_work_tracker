import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/errors/attendance_errors.dart';
import '../../../domain/entities/attendance_event_entity.dart';
import '../../../domain/entities/attendance_session_entity.dart';
import '../../../domain/entities/attendance_type.dart';
import '../../../domain/entities/shift_entity.dart';
import '../../../domain/repositories/attendance_repository.dart';

part 'attendance_session_state.dart';

/// Today's attendance for the whole app: the shift and the session.
///
/// Provided once in main.dart, so Home, the check-in/out flow and the
/// success screens all see the same session. Every state comes from the
/// repository's answer, never from what the user tapped.
class AttendanceSessionCubit extends Cubit<AttendanceSessionState> {
  AttendanceSessionCubit(this._repository)
    : super(const AttendanceSessionLoading());

  final AttendanceRepository _repository;

  String? _userId;

  /// Changes with the signed-in account; results for an older one are
  /// dropped.
  int _account = 0;

  /// Only the newest load may emit.
  int _loadId = 0;
  bool _recording = false;

  /// Call when the signed-in account changes (`null` when signed out).
  /// Clears the previous account's attendance before loading the new one.
  void userChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _account++;
    _recording = false;
    emit(const AttendanceSessionLoading());
    if (userId != null) load();
  }

  /// Loads today, or refreshes it. A failed refresh keeps what is shown.
  Future<void> load() async {
    // A save in progress emits its own, newer result.
    if (_recording) return;
    final account = _account;
    final loadId = ++_loadId;
    if (state is! AttendanceSessionLoaded) {
      emit(const AttendanceSessionLoading());
    }
    bool isStale() => !_isCurrent(account) || loadId != _loadId || _recording;
    try {
      final today = await _repository.getToday();
      if (isStale()) return;
      emit(AttendanceSessionLoaded(shift: today.shift, session: today.session));
    } catch (_) {
      if (isStale()) return;
      if (state is! AttendanceSessionLoaded) {
        emit(const AttendanceSessionError());
      }
    }
  }

  /// Saves a finished check-in or check-out flow.
  ///
  /// Throws an [AttendanceFailure] when saving fails, so the Review step
  /// can show the error and the user can try again without losing what they
  /// captured. When the server's state differs from what was shown, today
  /// is reloaded as well.
  Future<void> record(AttendanceEventEntity event) async {
    final current = state;
    if (current is! AttendanceSessionLoaded) throw AttendanceFailure.unknown;
    if (_recording) throw AttendanceFailure.busy;
    _recording = true;
    final account = _account;
    try {
      final session = switch (event.type) {
        AttendanceType.checkIn => await _repository.checkIn(event),
        AttendanceType.checkOut => await _repository.checkOut(
          current.session ?? (throw AttendanceFailure.notCheckedIn),
          event,
        ),
      };
      if (_isCurrent(account)) {
        emit(AttendanceSessionLoaded(shift: current.shift, session: session));
      }
    } on AttendanceFailure catch (failure) {
      if (failure.needsReload && _isCurrent(account)) {
        _recording = false;
        unawaited(load());
      }
      rethrow;
    } finally {
      if (_isCurrent(account)) _recording = false;
    }
  }

  bool _isCurrent(int account) => !isClosed && account == _account;
}
