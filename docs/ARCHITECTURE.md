# Architecture — EFS WorkTrack

## Overview

```
Flutter app (Android / iOS)                     Supabase
┌──────────────────────────────────┐            ┌──────────────────────────────────────┐
│ presentation  views, widgets,    │            │ Auth (email/password, reset link)    │
│               Cubits (flutter_bloc)            │ Postgres                              │
│ domain        entities, repository│  RPC/REST │   tables: RLS on, SELECT-only policies│
│               interfaces, rules   │──────────▶│   writes: SECURITY DEFINER functions  │
│ data          Supabase repositories│          │           calling private.require_actor│
│ core          theme, router, DI,  │            │   triggers: audit_change → audit_logs │
│               l10n, widgets       │            │   pg_cron: auto-close every minute    │
└──────────────────────────────────┘            │ Storage: private `attendance-evidence`│
                                                │ Edge Function: employee-accounts      │
                                                └──────────────────────────────────────┘
```

## Flutter

- **Layout:** `lib/app/features/<feature>/{domain,data,presentation}`. Shared code in
  `lib/core` (router, theme, widgets, errors, constants, `ClockCubit`).
- **State:** Cubits with sealed states. Keep it; no reason to change.
- **DI:** `get_it` (`setup()` in `main`) + `RepositoryProvider` / `BlocProvider` at the root.
- **Routing:** `go_router`; `AppRouter.redirectFor` is the single guard (signed-out,
  forced password change, admin-only `/admin/*`). The guard is UX only — the database
  enforces every rule again.
- **Business calculations** live outside widgets: `WorkDuration` (regular/overtime),
  `AttendanceSessionEntity`, employee statistics. Reports must reuse them, not re-derive.
- **Theme:** `AppPalette` → `AppTheme.lightFor(locale)` → `ThemeData`. Text roles in
  `AppTextStyles` carry no font family; the theme sets Manrope (English) or Cairo (Arabic),
  with Cairo as fallback for Arabic glyphs in English text. Fonts are bundled in
  `assets/fonts` (no runtime downloads).
- **Feature switches:** `Constants` (`accountRoleAndPhone`, `adminAttendanceCorrection`,
  `descriptiveEvidenceNames`) gate UI that needs a backend change.

## Backend authorization model (today)

- `profiles.role ∈ {employee, admin}` + `is_active` + `must_change_password`.
- `private.require_actor(p_admin)` is the gate inside every write RPC.
- `private.is_admin()` / `private.is_active()` are used by every RLS read policy.
- The planned permission system replaces the *checks*, not the structure: one
  `private.has_permission(code)` function used by RPCs and policies (see plan §3).

## Data flow: attendance

1. App uploads the selfie to `attendance-evidence/<uid>/<uuid>.jpg` (policy enforces the path).
2. `check_in(lat, lng, accuracy, path)` validates the schedule, GPS, selfie, server time and
   inserts `attendance_records` + `attendance_events`.
3. `check_out(...)` closes it; `pg_cron` auto-closes at the deadline (`auto_closed=true`).
4. Corrections only ever change `effective_*` + `has_correction`.

## Release

- Android: AGP 9.1, Kotlin 2.4, Java 17, R8 on; app keep rules in
  `android/app/proguard-rules.pro` (JNI plugins). Signed with the debug key — **a real
  upload key is required before Play Store release**.
- iOS: deployment target 15.0; permission texts in `Info.plist`; not built on this machine.
