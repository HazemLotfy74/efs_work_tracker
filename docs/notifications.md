# Android phone alerts

The in-app Alerts inbox uses the existing Supabase notification table. Android phone alerts require the following setup.

1. In [Firebase project settings](https://console.firebase.google.com/u/1/project/efs-work-tracker/settings/general), register or select the Android app `com.efs.efs_work_tracker`. Download `google-services.json` to `android/app/google-services.json`.
2. The device registration and delivery queue migration is already applied to the Work Tracker Supabase project. For a new environment, apply `supabase/ops/notification_push.sql` after creating the inbox.
3. Set `FIREBASE_SERVICE_ACCOUNT_JSON` and `PUSH_WORKER_SECRET` in Supabase Edge Function secrets. Use a service account authorized to send FCM messages for this Firebase project and a randomly generated worker secret. Keep both values server-side.
4. The `send-notification-push` Edge Function and its once-per-minute Supabase Cron job are already deployed. The job signs short-lived tokens with its own secret in Vault. `PUSH_WORKER_SECRET` supports manual calls to the sender.
5. Build the Android app with `flutter build apk --dart-define=ENABLE_PHONE_ALERTS=true`. Install it, sign in, open Alerts, tap the phone alerts button, and grant Android notification permission. Trigger a new request event for the test account while the app is in the background, then tap the phone alert to verify it opens the inbox.
