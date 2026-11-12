# HR reports — Attendance & Payroll Preparation (2026-11-11)

Admin → Dashboard → **HR reports**. Pick a month (arrows; future months are disabled), check the
figures, tap **Generate Excel**, then share or open the file from the phone's share sheet.
No database change was needed: everything is read through the existing admin RLS policies.

## Code

| Layer | File | Role |
|---|---|---|
| Domain | `hr_reports/domain/entities/hr_report.dart` | Period, input, rows, statuses |
| Domain | `hr_reports/domain/hr_report_builder.dart` | The only place the report is calculated |
| Data | `hr_reports/data/repositories/supabase_hr_report_repository.dart` | 4 parallel reads per month; temp file + share |
| Data | `hr_reports/data/hr_workbook.dart` | Report → 6 sheets (layout only) |
| Data | `hr_reports/data/xlsx/xlsx_writer.dart` | Minimal `.xlsx` writer |
| UI | `hr_reports/presentation/…` | `HrReportsCubit`, `HrReportsView`, route `/admin/reports` |

## Rules (all from `AttendanceSessionEntity`, same as the app screens)

- **Confirmed hours** only: a check-out by the employee, or an approved/admin correction.
  Days closed automatically count **no hours** until corrected (status "Missing check-out — HR review").
- **Regular / overtime:** first 8 confirmed hours of a day are regular, the rest overtime —
  from the check-in, not the clock (10:00 → 19:00 = 8 h + 1 h). Overtime is **calculated, not approved**.
- **Absence:** a passed scheduled working day (current schedule) with no record, for an active
  account, on/after its creation date. Today and future days are never absences.
- **Late / early:** `late_minutes` (DB, includes grace) / check-out before the record's `scheduled_end`.
- **Pending reviews:** missing check-outs + days with a pending correction (counted once per day).
- **Completion:** attendance days ÷ elapsed working days.
- Inactive accounts appear only if they have records in the month.

## Workbook

`Attendance_Report_YYYY_MM.xlsx`, sheets: Monthly HR Summary · Daily Attendance · Leave & Absence ·
Overtime · Exceptions & HR Review · Report Information.

- Title, period, then a header row that is frozen, filtered and repeated on printed pages;
  landscape, fit to width, A4.
- Real values: dates and times are Excel dates, hours are decimals (7.5 = 7 h 30 min), minutes integers.
- Colors from the app palette: green = confirmed, amber = needs attention, red = missing check-out.
- Arabic names stored as UTF-8 text. No formulas are written; text starting with `= + - @` gets
  Excel's quote prefix (formula-injection safe).
- Company totals row on the summary sheet.

### Shown as unavailable (never invented)

Approved leave and public holidays (no leave feature), approved/payable overtime (no approval
step), departments/job titles (not on profiles), salaries/rates/deductions/taxes. The information
sheet lists each one.

## Library choice

The `excel` package can't freeze panes, add auto filters or print titles, which the brief requires.
`syncfusion_flutter_xlsio` needs a commercial licence above a revenue threshold. So a ~300-line
writer on `archive` (MIT, pure Dart, already a transitive dependency) produces the file;
`share_plus` (BSD, Flutter Community, no JNI → no extra R8 rules) shares it; `path_provider` gives
the temp folder. APK size: 63.3 → 65.1 MB (includes the Cairo fonts added the same day).

## Security & privacy

- Reads: admin RLS policies; non-admins can't open `/admin/*` and the database would return only
  their own rows anyway. The workbook is built on a background isolate.
- File: written to `<temp>/hr_reports/`; the folder is emptied before each new report, so at most
  one copy exists. (Deleting right after sharing would break apps that read the file later.)
- **Not done (needs a DB change):** an audit row per export and a `reports.export` permission —
  part of the permissions work (IMPLEMENTATION_PLAN 4.1).

## Verification

| Check | Result |
|---|---|
| `test/hr_reports_test.dart` (engine + workbook, 16) | pass |
| `test/hr_reports_screen_test.dart` (cubit, data reads, share cleanup, screen EN + AR at 320 px, 9) | pass |
| Full suite | 341 pass |
| `flutter analyze` | only the 3 old infos in generated `assets.dart` |
| Opened in Microsoft Excel (read-only, via COM) | 6 sheets, filters on, values and date serials correct |
| `flutter build apk --release` | pass, 65.1 MB |
| On a phone | **not done** (phone not connected) |
| iOS | not built (needs macOS) |
