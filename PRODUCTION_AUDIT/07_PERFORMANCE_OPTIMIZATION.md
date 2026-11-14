# 07 — Performance and resources (2026-11-12)

**No runtime profiling was possible** (no device or emulator): startup time, frame times, memory,
CPU and battery were **not measured**. What follows is size measurement and code review.

## App size [run]
| Artifact | Size | Note |
|---|---|---|
| Single "fat" release APK (all ABIs) | 65.3 MB | What was shared before split builds were introduced |
| Release APK arm64-v8a | **23.0 MB** | What a modern phone should get |
| Release APK armeabi-v7a | 21.2 MB | Older 32-bit phones |
| Release APK x86_64 | 24.5 MB | Emulators |
| Release App Bundle | 62.8 MB upload | Google Play delivers one ABI per phone (≈ the APK sizes above) |

Sizes are in MiB (the App Bundle is 65,874,835 bytes; the arm64 APK 24,135,614). The single fat APK
is from an earlier build (11 Nov), the others from this audit. No size change was made in this
audit. Icon fonts are tree-shaken to under 11 KB. Fonts: 764 KB (Manrope + Cairo, four
weights each); images 30 KB. Nothing large is unused.

## Code review [read]
| Area | Finding |
|---|---|
| Timers | One 1-second timer (`ElapsedTimeText`, only while a session card is visible, cancelled on dispose); one per-minute clock (`ClockCubit`) |
| Polling / realtime | None. Data reloads on screen open, pull-to-refresh, app resume and after the user's own actions |
| Background work | None in the app. No background location, no wake locks requested by app code |
| Network per screen | Home: profile + schedule, today's record, approved overtime (3 reads). Admin dashboard reads employees, schedules and today's records once per open |
| Stale responses | Cubits drop results of superseded loads (load ids) |
| Images | Selfies are captured at max width 1080, quality 80, before upload |
| Disposal | Controllers, subscriptions and timers are disposed in the screens and cubits reviewed |
| Startup | `Supabase.initialize` then (Android, only when enabled) Firebase with a 5-second cap; nothing else blocks the first frame |

## Database [read]
8 attendance rows, 8 profiles: no query is slow and no index is missing for the app's reads
(all filter on indexed `employee_id`, `work_date`, `status`). Advisors' "unused index" notices
reflect the tiny data set, not a problem.

## Findings
| ID | Sev | Finding | Status |
|---|---|---|---|
| P-1 | P2 | No measured startup, memory or frame data on a real device | Open — needs a device (`flutter run --profile`, DevTools) |
| P-2 | P3 | Admin dashboard and HR reports load every employee and up to 300 recent days in one request; fine for dozens of employees, needs paging for hundreds | Open — revisit before the company grows past ~100 employees |
| P-3 | P3 | On app resume, attendance, permissions and inbox each reload (3–5 requests) | Open — acceptable |
| P-4 | P3 | `main.dart` reloaded attendance twice on every resume (merge leftover) | **Fixed** |
