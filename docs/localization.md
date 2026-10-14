# Localization

Daisth supports Indonesian (`id`) and English (`en`). The initial language
preference is **System Default**. A supported system locale selects its
language; an unsupported or unavailable locale falls back to English.

Settings → Appearance → Language offers **Ikuti Sistem / System Default**,
**Indonesia**, and **English**. Indonesia and English override the device
language. Returning to System Default resumes following OS locale changes. The
app root resolves the preference and owns the effective `MaterialApp.router`
locale so screens switch immediately without restarting or resetting
navigation.

The stable preference values are `system`, `id`, and `en`. They are stored in
device-local `app_settings.language_mode` in `daisth.db`. They are not
associated with a Firebase UID and are excluded from the Firestore sync model
and outbox. Sign-out and account changes leave the local preference unchanged.

When the effective language changes, future reminder plans are reconciled
through the existing reminder settings path. Notification action identifiers
and payloads remain stable. A background action reads the local preference and
resolves System Default from platform locales, falling back to English without
using a `BuildContext`.

The intentionally shared product terms are **Masjid**, **Mushola**, and
**Zikir**. Other Daisth-owned interface copy is localized naturally. English
prayer labels use Fajr, Dhuhr, Asr, Maghrib, and Isha; Sholat Malam and Penutup
Hari use Night Prayer and End of Day. Stable IDs remain unchanged.

User-authored routine titles, descriptions, checklist steps, and reflection
notes remain exactly as written. External place names, legal/source text, and
verified religious source content (including Arabic, translations, and
transliterations) are preserved.

Localization uses project-native presentation copy and `DaisthTerminology` for
stable product terminology. Locale preference and resolution tests live under
`test/localization/`; the Settings picker runtime switch test lives under
`test/settings/`.
