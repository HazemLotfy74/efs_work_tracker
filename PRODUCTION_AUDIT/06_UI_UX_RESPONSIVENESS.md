# 06 — UI, UX and responsiveness (2026-11-12)

Checked with widget tests that fail on any layout overflow or exception; **not** by looking at the
screens on a device (none attached) — spacing, colour and visual polish were not reviewed by eye.

## Automated layout coverage [run]
| Screens | Widths | Text scale | Languages | Themes |
|---|---|---|---|---|
| Home, attendance details, history, profile, login, forgot password, empty / error / loading / permission states | 430 px | 1.0×, 1.3× | English | light, dark |
| Home card and check-in states | 360 px | 1.0× | Arabic | light |
| Home (with reviewer shortcut), assigned reviews, my corrections | 320, 390 px | 1.0× | Arabic, English | light |
| Admin dashboard, employee page, permissions, requests, edit employee, HR reports | 390 px | 1.0× | English | light |

All pass (part of the 389).

## Design system [read]
One theme (`core/theme`), semantic colours via a theme extension, shared widgets (`CustomContainer`,
`AppPrimaryButton`, `CustomStatusContainer`, `App*View` state screens, `AppDialog`, `showAppSnackBar`).
Manrope for Latin, Cairo for Arabic. New screens from earlier sessions use these; no ad-hoc colours found.

## Fixed during recent work (already in the code)
- Home greeting row overflowed at 390 px with a two-word name.
- "Check In Now" label overflowed at 360 px.
- Attendance-details events row overflowed with long text.

## Findings
| ID | Sev | Finding | Status |
|---|---|---|---|
| U-1 | P2 | No visual review on a real device, in either language | Open (see 05) |
| U-2 | P3 | Admin screens are layout-tested at one width and in English only | Open — add Arabic + 320 px cases |
| U-3 | P3 | No screen-reader (semantics) audit | Open |
| U-4 | P3 | Form validation messages in `form_validator_functions.dart` are English-only | Open |
| U-5 | P3 | Landscape is not locked and not tested | Open — lock to portrait or test |
