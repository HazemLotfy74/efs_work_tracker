# Admin management, per-employee permissions and corrections — status (2026-11-11)

Scope: the "Advanced Admin Management / Dynamic Permissions / Attendance Correction" brief.
The database was inspected read-only and **not changed** (47 functions, 16 policies, 9 tables
before and after; no flag set, nothing assigned). All work is in the Flutter app.

## 1. What the live database already has (found in this audit)

The permission system is **not** the 15-code design in `supabase/migrations/20261111090000_permissions.sql`
(never applied, rolled back once). The live database has its own, simpler model, which the app did not use:

| Object | What it does |
|---|---|
| `profiles.can_review_expense_advances`, `can_review_overtime`, `can_review_attendance_corrections` | Per-employee reviewer flags. Readable on your own row |
| `admin_set_*_reviewer_permission(employee, enabled)` | Admin only; employee accounts only |
| `*_requests.assigned_reviewer_id` + `admin_assign_*_reviewer(request, reviewer)` | An admin assigns a **pending** request to an active employee who holds the flag; never the requester; `null` unassigns |
| RLS `*_read_assigned_reviewer` | A reviewer reads **only** the request rows assigned to them |
| `review_assigned_expense_advance` / `_attendance_correction` / `_overtime` | The reviewer decides an assigned request; checks flag, assignment, pending status, never their own |
| `admin_edit_employee_profile(id, full_name, username, employee_code)` | Admin edits an employee account (validated, normalized) |
| `admin_request_employee_email_change`, `get_employee_login_email`, trigger `attendance_guard_employee_login_email` | Admin opens a 24-hour request; the employee changes the email through Supabase Auth; any other address is refused |

Roles are still only `admin` and `employee`. There is no role table, no inheritance and no
"revoke" override: an admin holds everything through the role; an employee holds what the flags say.

## 2. Status per requested feature

| Feature | Status |
|---|---|
| Permissions Management screen on the employee page (switches, description, review-and-save, confirmation) | **Done, tested.** Three switches: review assigned cash requests, attendance corrections, overtime. Admin accounts show locked |
| App follows the signed-in user's effective permissions (navigation, buttons, route guard) | **Done, tested.** Read from the user's own profile row at sign-in and app resume; removed on the next refused action |
| Admin assigns a reviewer to a cash request / correction request | **Done, tested** |
| Reviewer screen "Assigned to me" (approve / reject with note) + Home shortcut | **Done, tested** |
| Edit employee: full name, username, employee code | **Done, tested** |
| Change login email (admin requests, employee confirms) | **Built, tested with fakes; not verified end to end** — depends on the project's Auth email settings, which I can't read |
| Suspend / reactivate | Already existed; unchanged |
| Schedule assignment | Already existed; unchanged |
| Correction requests from Home, beside cash requests, with history, status and reviewer note | **Done, tested** |
| Correction review by admin; approval applies effective times, keeps originals, audited | Already existed; unchanged |
| Delete employee | **Not built.** Every table references the employee with `ON DELETE RESTRICT` and no delete/archive function exists. Deactivation keeps all history |
| Phone, department, job title, role editing | **Not built.** No function edits phone or role; no department / job-title columns exist |
| "Missing check-in" and typed corrections | **Not built.** `request_attendance_correction` needs an existing day and has no type column. The day picker labels a day "Missing check-out" or "Incorrect times" from what it recorded |
| Fine-grained codes (view-only vs approve vs reject, manage employees, manage permissions for non-admins) | **Not possible on the live model.** A flag grants "decide what is assigned to you"; everything else is the admin role |
| Notifications on approval / rejection | **Not built.** No notification table, function or push setup exists |
| Overtime review | Flag is shown and can be granted, but the app has no overtime requests (overtime is calculated), so it opens nothing |

## 3. Limits of the live model worth knowing

1. **A delegated reviewer cannot see who sent the request or the original attendance day.** RLS gives
   them the request row only (amount, reason, proposed times), not the requester's profile or the
   recorded times. The screen says so. Showing them needs a database change (a policy or a function).
2. **Saving several permission switches is not atomic** (one function per flag). After a failure the
   screen reloads what the database holds.
3. **A grant appears on the employee's phone at their next sign-in or app resume**, not instantly.
   A removal is enforced by the database immediately; the app hides the screen on the next refusal.
4. `admin_assign_overtime_reviewer` / `review_assigned_overtime` are not used by the app.

## 4. Files

New
- `lib/app/features/assigned_reviews/**` (repository, cubit, view)
- `lib/app/features/admin/presentation/widgets/assign_reviewer_button.dart`
- `lib/app/features/admin/presentation/views/edit_employee_view.dart`
- `lib/app/features/attendance_correction/presentation/views/my_corrections_view.dart`
- `lib/app/features/profile/presentation/widgets/pending_email_change.dart`
- `test/delegated_reviews_test.dart` (20 tests)

Changed
- Permissions: `permission_set.dart`, `permission_repository.dart`, `supabase_permission_repository.dart`
  (now the live flags), `permissions_cubit.dart`, `manage_permissions_cubit.dart`,
  `manage_permissions_view.dart`; `Constants.dynamicPermissions = true`.
- Admin: `employee_entity.dart`, `admin_request_entity.dart`, `admin_repository.dart`,
  `supabase_admin_repository.dart`, `admin_requests_view.dart`, `employee_details_view.dart`,
  `admin_failure_text.dart`, `admin_errors.dart`.
- Corrections: entity, model, repository interface + Supabase implementation, `correction_review_card.dart`,
  `pending_corrections_view.dart`.
- Auth: `auth_repository.dart`, `supabase_auth_repository.dart`, `supabase_auth_service.dart`, `auth_cubit.dart`.
- Home / profile / routing / DI: `home_view_body.dart`, `user_header.dart` (overflow fix),
  `profile_view_body.dart`, `app_routes.dart`, `app_router.dart`, `getit_services.dart`, `main.dart`.
- `app_en.arb`, `app_ar.arb` (+ generated), `test/permissions_test.dart`, test fakes.

## 5. Security checks (app side; the database enforces each rule itself)

- Reviewer reads always filter on `assigned_reviewer_id = me` and `status = pending`; own-request
  lists filter on `employee_id = me` (an admin's RLS would otherwise return everyone's).
- The route guard sends a reviewer home from every `/admin/...` screen; `/reviews` needs a flag;
  `/admin/employees/:id/edit` needs the admin role.
- "Assign reviewer" offers only active employees who hold the flag, have changed their first
  password, and are not the requester — the same rules the function applies.
- No service-role key in the app. No raw database error text is shown.

## 6. Verification actually run

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings (3 pre-existing infos in a generated file) |
| `flutter test` | **386 passed, 0 failed** (363 before; 20 new; the 2 tests for the unapplied migration replaced by 5 for the live flags) |
| `flutter build apk --release --split-per-abi` | Built: arm64 22.9 MB, armeabi-v7a 21.0 MB, x86_64 24.2 MB |
| Live database | Read-only; object counts and data unchanged |

Not run: any test against the real database (production only; granting a flag or assigning a
request would change real records) and on-device runs. The permission matrix was therefore
verified against the function definitions and with fakes, **not** with real accounts.

Bug found and fixed on the way: the Home greeting row overflowed on 390 px phones with a
two-word name (`user_header.dart`).

## 7. To try it for real (your action, on real accounts)

1. Admin → employee page → **Permissions** → switch on "Review assigned cash requests" → save.
2. Admin → Cash requests → **Assign reviewer** on a pending request → pick that employee.
3. That employee: reopen the app → Home shows **Assigned to me** → approve or reject.
4. Email change: admin → employee page → **Edit details** → request a new login email; the
   employee opens Profile → **Send confirmation email** → opens the link.
