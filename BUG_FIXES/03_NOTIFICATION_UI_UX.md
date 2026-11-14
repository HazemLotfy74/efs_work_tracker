# 03 — Notification screen (2026-11-13)

**Status: FIXED BUT NOT FULLY VERIFIED.** Rebuilt and covered by layout tests at four screen sizes,
two languages and three text sizes. Not looked at on a real device.

## Root cause
The Alerts screen was plain Material `ListTile`s, a bare `AlertDialog` and one-line text states.
It used none of the app's cards, colours, spacing, state views or dialogs.

## What changed (only `inbox_view.dart`; no other screen touched)
| Part | Now |
|---|---|
| Card | The app's card shape (16 radius, outline, 16 padding), like the request cards |
| Icon | One per request type in a tinted square: correction, cash, overtime |
| Colour | By what happened, from the theme: approved green, rejected red, waiting amber |
| Unread | Tinted card, bold title, coloured event line and a dot. Read: plain card, regular weight |
| Text | Title = request type, then the event, then date · time (small, muted). Wraps; nothing is cut |
| Empty / loading / error | The shared `AppEmptyView`, `AppLoadingView`, `AppErrorView` |
| Refresh failed with a list shown | The list stays; a banner with a retry button appears above it |
| Pull to refresh | Works on the list and on the empty and error states |
| Detail | The app's `AppDialog`: status badge, the employee's reason, and for a decision the reviewer's reason in a green or red box |
| Request no longer visible | "This request is no longer available to you." |
| RTL | Directional padding; icon at the start, dot at the end |

Behaviour kept: a notification is marked read only when opened; the database decides what the user
may open; the badge on the tab comes from the same cubit.

## Tests run (`test/notification_inbox_view_test.dart`, 31 tests — passed)
| Check | Result |
|---|---|
| No overflow at 320×568, 375×667, 430×932, 480×1040 × Arabic/English × text 1.0/1.3/1.6 (24 cases) | passed |
| Arabic is right-to-left; dot on the trailing side | passed |
| Unread vs read; one icon per type; no duplicates | passed |
| Scrolling the list marks nothing read | passed |
| Opening marks only that one read and shows the decision reason | passed |
| Unavailable request message | passed |
| Empty state, error state, retry | passed |
| Failed refresh keeps the list | passed |

Two defects were found by these tests and fixed before finishing: the empty/error state broke inside
the pull-to-refresh area, and the "signed in on another device" message never appeared.

## Not verified
- Appearance on real Android and iPhone screens and densities.
- Screen reader behaviour (an "unread" label is provided; not tested with TalkBack/VoiceOver).

## Known leftovers
- `AppErrorView`'s button says "Try again" in English in every language (shared widget, not changed here).
- Tapping a notification shows the request in a dialog; it does not open the full request page.
