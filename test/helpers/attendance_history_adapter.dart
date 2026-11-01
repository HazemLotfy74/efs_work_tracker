import 'package:efs_work_tracker/app/features/attendance_session/domain/entities/attendance_session_entity.dart';
import 'package:efs_work_tracker/app/features/attendance_session/domain/repositories/attendance_repository.dart';
import 'package:efs_work_tracker/app/features/history/domain/repositories/history_repository.dart';

/// Keeps legacy attendance test fixtures reusable by history widget tests.
class AttendanceHistoryAdapter implements HistoryRepository {
  AttendanceHistoryAdapter(this.repository);
  final AttendanceRepository repository;

  @override
  Future<List<AttendanceSessionEntity>> getMonth(DateTime month) =>
      repository.getHistory(month: month);
}
