# 04 — Mandatory reason for correction decisions (2026-11-13)

**Status: FIXED BUT NOT FULLY VERIFIED.** The app requires a reason for both approve and reject, and
the database rule is live since 2026-11-12 22:08 UTC: in the production dry run a decision without a
reason on the real pending request was refused. Not exercised from a phone yet.

## Root cause
`review_request` and `review_assigned_attendance_correction` take `p_note … DEFAULT NULL` and store
`nullif(btrim(p_note), '')`. The table's `correction_review_state` check does not ask for a note, and
the app's dialog labelled the field "Note (optional)". Live data: 1 of the 2 decided requests has no note.

## Existing schema — reused, nothing duplicated
`attendance_correction_requests` already holds everything asked for:
`id`, `employee_id`, `reviewed_by` (who), `status` (what), `review_note` (why), `reviewed_at` (when).
Changes go to `audit_logs` through the existing `audit_change` trigger. Clients have no write grant on
the table; a decided request cannot be decided again ("already been reviewed").

## Database (migration section 3)
| Object | Purpose |
|---|---|
| Check `correction_decision_reason` (`NOT VALID`) | A decided row must have a reason with visible text, at most 2000 characters. `NOT VALID` keeps the one historical decision without a note; every new or changed row is checked |
| Trigger `require_correction_decision_reason` | Same rule with a clear error (`22023`, "A decision reason of 1-2000 characters is required") |

The rule is on the **table**, so both review functions — and any future one — obey it without being
rewritten. The attendance change made earlier in the same call is rolled back with it.

Found by the tests and fixed: `btrim` only removes spaces, so a "reason" of line breaks or tabs
passed; and a check on a `NULL` note evaluated to unknown and passed. The rule now requires a
non-whitespace character and an explicit not-null.

## App
| Where | Change |
|---|---|
| `review_decision_dialog.dart` | For corrections: shows the request details, a field labelled «سبب الموافقة» / «سبب الرفض» with the asked placeholders, "required" helper text, and a confirm button («تأكيد الموافقة» / «تأكيد الرفض») that stays disabled until there is text. Titles «تأكيد قبول طلب التصحيح» / «تأكيد رفض طلب التصحيح» |
| `correction_review_card.dart`, `assigned_reviews_view.dart` | Admin queue and delegated reviewers both use it |
| `supabase_correction_repository.dart`, `supabase_assigned_review_repository.dart` | Refuse an empty or over-long reason before sending; map the database's refusal to the same message |
| `correction_request_details.dart` | The employee sees the decision in its own green or red box: «سبب الموافقة» or «سبب الرفض», the text, and the decision date and time |
| `inbox_view.dart`, `inbox_repository.dart` | The notification detail shows the decision reason too |

The employee is notified of the decision by the existing trigger; the reason is read in the app.

Cash and overtime decisions keep their optional note: the request was about attendance corrections.

## Tests run — all passed
| # | Matrix item | Where |
|---|---|---|
| 1–2 | Approve / reject with a reason | SQL test; repository test; widget test |
| 3–5 | Empty, spaces, line-breaks-only reason | SQL (refused `22023`); repository (nothing sent); widget (button disabled) |
| 6 | 2001 characters | SQL refused; repository `noteTooLong` |
| 7–8 | Unauthorised approve / reject | Existing tests (employee → not allowed; own request refused) |
| 9 | Direct backend call without a reason | SQL test on the table; fake-server test |
| 10 | Employee sees the reason | Widget tests (history card and notification detail) |
| 11 | History unchanged; a decision cannot be replaced | SQL (old row kept); repository test (second review refused, first reason kept) |

Not run: any of this against the live database (migration not applied), or on a device.
