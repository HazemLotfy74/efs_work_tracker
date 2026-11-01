import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/attendance_errors.dart';
import '../../../../../core/services/database_services.dart';
import '../../../attendance_session/domain/entities/attendance_session_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/attendance_history_model.dart';

/// Reads only the signed-in employee's selected month through Supabase RLS.
class SupabaseHistoryRepository implements HistoryRepository {
  SupabaseHistoryRepository({
    required DatabaseServices databaseServices,
    required this._currentUserId,
    this.timeout = const Duration(seconds: 20),
  }) : _database = databaseServices;

  final DatabaseServices _database;
  final String? Function() _currentUserId;
  final Duration timeout;

  @override
  Future<List<AttendanceSessionEntity>> getMonth(DateTime month) async {
    final userId = _currentUserId();
    if (userId == null) throw AttendanceFailure.accountNotReady;
    final Object? rows;
    try {
      rows = await _database
          .getData(
            path: 'attendance_records',
            column: AttendanceHistoryModel.columns,
            query: {'employee_id': userId},
            greaterThanOrEqual: {
              'work_date': _date(DateTime(month.year, month.month)),
            },
            lessThan: {
              'work_date': _date(DateTime(month.year, month.month + 1)),
            },
            orderBy: 'work_date',
            descending: true,
            // One record per work date: at most 31 rows in a month.
            limit: 60,
          )
          .timeout(timeout);
    } on PostgrestException catch (error) {
      log('History read failed: code ${error.code}');
      throw switch (error.code) {
        '42501' ||
        'PGRST301' ||
        'PGRST303' => AttendanceFailure.accountNotReady,
        'PGRST202' || 'PGRST205' => AttendanceFailure.serviceUnavailable,
        _ => AttendanceFailure.unknown,
      };
    } on Exception catch (error) {
      log('History read failed: ${error.runtimeType}');
      throw AttendanceFailure.network;
    }
    try {
      return [
        for (final row in (rows as List).cast<Map>())
          AttendanceHistoryModel.fromJson(Map<String, dynamic>.from(row))
              .toEntity(),
      ];
    } catch (error) {
      log('Unreadable history: ${error.runtimeType}');
      throw AttendanceFailure.unknown;
    }
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-01';
}
