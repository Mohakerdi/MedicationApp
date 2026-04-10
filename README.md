# Medication Alarm (Offline-First Flutter)

This app is an offline-first medication reminder designed for reliability.

## What it implements

- Local-only persistence with SQLite (`sqflite`):
  - `medications`
  - `dose_schedules`
  - `alarm_instances`
  - `dose_logs`
- Exact timezone-aware scheduling (`timezone` + `flutter_local_notifications`)
- Full-screen Android alarm notifications for high urgency
- Must-dismiss alarm screen with explicit actions:
  - **Take now**
  - **Snooze 10 min**
  - **Skip**
- Startup reconciliation:
  - marks stale pending alarms as missed
  - re-seeds/schedules missing alarms after reboot or process death
- iOS-safe rolling horizon scheduling (next 14 days)
- English + Arabic localization support
- MVVM-style presentation flow with dedicated view models
- Animated splash screen and one-time landing page onboarding
- Centralized app theming in `lib/theme/`
- Alarm schedule CSV export/import

## Platform behavior

### Android

- Primary target for true alarm-like behavior.
- Uses full-screen intent notifications and exact alarm scheduling.
- Includes manifest permissions and boot receiver wiring to improve persistence.

### iOS

- Uses high-urgency local notifications.
- iOS may not force-open the app on lock screen like Android full-screen intents.
- App schedules a rolling horizon of upcoming reminders.

## Notes

- No Firebase or internet dependency is required.
- Data remains on-device only; uninstalling app removes data.
- For production, add backup/export and richer accessibility tuning.
