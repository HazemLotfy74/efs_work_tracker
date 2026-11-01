# Proposal (NOT applied): descriptive file names for attendance selfies

Status: **waiting for your approval.** Nothing was changed in Supabase. The app side is
ready behind `Constants.descriptiveEvidenceNames` (currently `false`).

## Why it needs a policy change

Selfies are stored in the private bucket `attendance-evidence` at `<auth uid>/<uuid>.<ext>`.
The upload policy only allows exactly that shape:

```sql
-- storage.objects, policy attendance_selfie_upload (INSERT, authenticated)
name ~ ('^' || auth.uid() || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](jpg|jpeg|png|webp)$')
```

A descriptive name such as
`5f6e…/Ahmed_Mohamed_EMP-125_check_in_20261101_060530_a81f2c0d.jpg` is refused by Storage,
so turning the app option on without this change would make **every check-in fail**.

`check_in` / `check_out` themselves accept any name: `private.assert_selfie` only requires the
`<auth uid>/` folder and an existing object owned by the user. The read policy also keys on the
folder and on the path stored in `attendance_events`, so it needs no change.

## Name format (implemented in `EvidenceFileName`)

`<auth uid>/<name>_<employee code>_<check_in|check_out>_<yyyyMMdd_HHmmss UTC>_<8 hex>.<ext>`

- `<name>`: the full name reduced to ASCII letters/digits (`Ahmed Mohamed` → `Ahmed_Mohamed`).
  Arabic or empty names fall back to the username (ASCII by its constraint). Max 40 chars.
- `<employee code>`: stable, ASCII by constraint (`^[A-Z0-9][A-Z0-9_-]{1,49}$`).
- the event type, so a day's two photos never share a name;
- the capture time in UTC (naming only; the official times are set by the server);
- 8 random hex characters, so every photo is unique; a retry of the same photo reuses its name.

## Proposed policy (allows the old and the new shape)

```sql
alter policy attendance_selfie_upload on storage.objects
with check (
  bucket_id = 'attendance-evidence'
  and (select private.is_active())
  and owner_id = (select auth.uid())::text
  and (
    -- existing shape
    name ~ ('^' || (select auth.uid())::text
            || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](jpg|jpeg|png|webp)$')
    -- descriptive shape: ASCII only, no further folders, unique suffix
    or name ~ ('^' || (select auth.uid())::text
            || '/[A-Za-z0-9_-]{1,120}_check_(in|out)_[0-9]{8}_[0-9]{6}_[0-9a-f]{8}[.](jpg|jpeg|png|webp)$')
  )
);
```

Nothing else changes: the bucket stays private, objects stay owner-only, delete/update stay
blocked, and existing photos keep their names.

## After approval

1. Run the SQL above (Supabase SQL editor or a migration).
2. Set `Constants.descriptiveEvidenceNames = true` in `lib/core/constants/constants.dart`.
3. Check in once; in Storage → `attendance-evidence/<your uid>/` the new photo has the
   descriptive name, and the admin day page shows it.

Rollback: restore the old `with check` expression and set the constant back to `false`.
