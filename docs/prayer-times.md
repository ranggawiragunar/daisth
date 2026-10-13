# Prayer times

Daisth calculates the daily schedule on device with `adhan_dart` and the
Indonesia (KEMENAG) calculation preset. Shafi is the default Asr method. The
calculation includes Sunrise for future daytime-window logic, but Sunrise is
not a mandatory prayer routine.

The current flow requests foreground location only after a user action when
permission is missing. A previously granted permission allows Today to load
automatically. If a fresh coordinate cannot be read, the app may calculate from
the last-known location and labels that schedule. The schedule and settings live
in memory for the app session; coordinates are not persisted. Settings displays
only a user-facing location access state and the current device IANA timezone;
it does not show coordinates. Opening Settings checks access without requesting
permission. Permission requests and system settings actions require an explicit
tap. Prayer refresh uses the shared schedule session and normal reminder
reconciliation. No Kemenag API, background location, or notification scheduler
is used by the prayer calculation service.

Prayer values are converted to device-local time and shown in 24-hour `HH:mm`
format. This assumes the device timezone matches the current physical location.
Manual remote-location selection and coordinate-to-timezone lookup are not
implemented.

## Jakarta sanity benchmark

The service test checks the Jakarta coordinate `-6.2, 106.8166` for
`2026-10-10` against the approximate Kemenag schedule below. It allows a
five-minute difference because location coordinates and rounding conventions
can vary.

| Prayer | Kemenag reference | `adhan_dart` result | Difference |
| --- | ---: | ---: | ---: |
| Subuh | 04:18 | 04:16 | -2 min |
| Zuhur | 11:43 | 11:41 | -2 min |
| Asar | 14:44 | 14:42 | -2 min |
| Maghrib | 17:49 | 17:46 | -3 min |
| Isya | 18:58 | 18:56 | -2 min |

This is a regression sanity check, not a runtime override or source of truth.
