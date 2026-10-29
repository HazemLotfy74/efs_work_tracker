import 'package:get_it/get_it.dart';

import '../../app/features/admin/data/repositories/supabase_admin_repository.dart';
import '../../app/features/admin/domain/repositories/admin_repository.dart';
import '../../app/features/attendance_correction/data/repositories/supabase_correction_repository.dart';
import '../../app/features/attendance_correction/domain/repositories/correction_repository.dart';
import '../../app/features/attendance_session/data/repositories/supabase_attendance_repository.dart';
import '../../app/features/attendance_session/domain/repositories/attendance_repository.dart';
import '../../app/features/auth/data/repositories/supabase_auth_repository.dart';
import '../../app/features/auth/domain/repositories/auth_repository.dart';
import '../../app/features/cash_request/data/repositories/supabase_expense_advance_repository.dart';
import '../../app/features/cash_request/domain/repositories/expense_advance_repository.dart';
import 'accounts_function.dart';
import 'database_services.dart';
import 'storage_services.dart';
import 'supabase_auth_service.dart';
import 'supabase_database_services.dart';
import 'supabase_storage_services.dart';

final getIt = GetIt.instance;

/// Call once in main.dart, after `Supabase.initialize`.
void setup() {
  getIt.registerSingleton<SupabaseAuthService>(SupabaseAuthService());
  getIt.registerSingleton<DatabaseServices>(SupabaseDatabaseServices());
  getIt.registerSingleton<StorageServices>(SupabaseStorageServices());
  getIt.registerSingleton<AuthRepository>(
    SupabaseAuthRepository(
      authService: getIt<SupabaseAuthService>(),
      databaseServices: getIt<DatabaseServices>(),
    ),
  );
  getIt.registerSingleton<AttendanceRepository>(
    SupabaseAttendanceRepository(
      databaseServices: getIt<DatabaseServices>(),
      storageServices: getIt<StorageServices>(),
      currentUserId: () => getIt<SupabaseAuthService>().currentUser?.id,
    ),
  );
  getIt.registerSingleton<CorrectionRepository>(
    SupabaseCorrectionRepository(
      databaseServices: getIt<DatabaseServices>(),
      currentUserId: () => getIt<SupabaseAuthService>().currentUser?.id,
    ),
  );
  getIt.registerSingleton<ExpenseAdvanceRepository>(
    SupabaseExpenseAdvanceRepository(
      databaseServices: getIt<DatabaseServices>(),
      currentUserId: () => getIt<SupabaseAuthService>().currentUser?.id,
    ),
  );
  getIt.registerSingleton<AdminRepository>(
    SupabaseAdminRepository(
      databaseServices: getIt<DatabaseServices>(),
      accountsFunction: invokeAccountsFunction,
      currentUserId: () => getIt<SupabaseAuthService>().currentUser?.id,
    ),
  );
}
