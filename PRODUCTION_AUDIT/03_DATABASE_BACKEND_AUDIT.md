# 03 — Database and backend audit (2026-11-12)

Read-only inspection of the production database (catalog queries, Supabase advisors, function
source). **No statement that changes data, schema or settings was run.**

## Integrity [read]
| Check | Result |
|---|---|
| Tables with RLS enabled | 13 of 13 |
| Client (`anon` / `authenticated`) write grants on tables | none (SELECT only) |
| Functions executable by `anon` | none |
| `admin_*` functions without `require_actor(true)` | none |
| Client-callable SECURITY DEFINER functions without an identity check | none |
| SECURITY DEFINER functions without a pinned `search_path` | none |
| Foreign keys in `public` without an index | none |
| Foreign keys | all `ON DELETE RESTRICT` (history cannot be orphaned) |
| Uniqueness | employee code, username, one record per employee per day, one event of each type per day, one selfie per event, one pending correction per day |
| Append-only | `attendance_events`, `audit_logs` (trigger rejects UPDATE / DELETE) |
| Audit | trigger on every business table |

## Data consistency [read]
| Check | Result |
|---|---|
| Auth users without a profile | 0 |
| Events without a record / records without a check-in event | 0 / 0 |
| Open records past their close deadline | 0 |
| Selfies not referenced by any event | 6 of 21 |
| Cron failures in the last 24 h | 0 (auto-close 1,440 runs; push 218 runs) |

## Supabase advisors [run]
| Advisor | Level | Assessment |
|---|---|---|
| 26 SECURITY DEFINER functions callable by signed-in users | WARN | Intended design; each checks the caller (verified above) |
| Leaked-password protection disabled | WARN | **Enable it** (Auth → Password security) |
| `pg_net` extension | WARN | See D-2 |
| RLS enabled, no policy (3 `private` tables) | INFO | Correct: clients must not read them |
| Multiple permissive SELECT policies (3 request tables) | WARN (perf) | Negligible at this size |
| 3 unindexed FKs in `private`, 12 unused indexes | INFO | No action at this size |

## Findings
| ID | Sev | Finding | Recommended action (yours — I do not change the database) |
|---|---|---|---|
| D-1 | P2 | **No migration history and no staging database.** Changes are typed into production; an earlier change this month broke all signed-in reads for 3½ minutes before rollback | Keep every change as a file; dry-run in a transaction that rolls back; ideally a second (free) project for testing |
| D-2 | P3 | `net.http_get/post/delete` are executable by `anon` and `authenticated`. Not reachable through the API unless the `net` schema is exposed (could not be checked) | `revoke execute on all functions in schema net from anon, authenticated;` after confirming nothing client-side needs it |
| D-3 | P3 | Storage policies `attendance_selfie_no_update` / `_no_delete` are permissive with `bucket_id <> 'attendance-evidence'`: they would let anyone update/delete objects in **any other** bucket. Harmless today (one bucket) | Drop them (no policy already means deny) before adding a second bucket |
| D-4 | P3 | Orphaned selfies cannot be removed by clients | A scheduled server-side cleanup of unreferenced objects older than a day |
| D-5 | P2 | Auth settings could not be read: access-token hook enabled? public sign-ups off? redirect URLs? email-change confirmation? | Check in the dashboard (list in 04) |

## Not done
- Acting as each role against the database (blocked by this session's safety controls).
- Concurrency tests (two simultaneous check-ins): only the locking code was read, not exercised.
- Query plans / load tests: 8 attendance rows exist; nothing meaningful to measure yet.
