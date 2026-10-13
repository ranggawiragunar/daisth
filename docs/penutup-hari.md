# Penutup Hari

Penutup Hari is the built-in optional bedtime routine with stable ID
`penutup-hari`. Its default preferred time is 21:00. Routine Management owns
the user's enabled, time, and reminder settings; startup never replaces an
existing routine definition. Reset to Default restores 21:00 and the default
enabled, reminder, and priority values without touching daily records.

## Steps and completion

The built-in capability has seven stable step IDs:

| ID | Label | Requirement |
| --- | --- | --- |
| `wudu` | Wudu | Optional |
| `ayat-kursi` | Ayat Kursi | Required |
| `al-ikhlas` | Al-Ikhlas | Required |
| `al-falaq` | Al-Falaq | Required |
| `an-nas` | An-Nas | Required |
| `al-baqarah-285-286` | Al-Baqarah 285–286 | Required |
| `doa-sebelum-tidur` | Doa Sebelum Tidur | Required |

All six required steps must be complete for the routine status to be
`Completed`. Some but not all required steps means `Partial`; Wudu alone does
not mean `Partial`. Mark All, Mark Remaining, and notification Done complete
the required readings while leaving Wudu as it was. Unchecking a required step
returns a completed routine to `Partial` and clears `completed_at_utc`.

The steps are a built-in capability, not rows in the user-editable
`routine_step_definitions` checklist. They use the existing daily routine and
step record tables; the database remains schema v4.

## Reader

Penutup Hari resolves these local Reader content IDs:

```text
ayat-kursi
al-ikhlas
al-falaq
an-nas
al-baqarah-285-286
doa-sebelum-tidur
```

The bedtime dua reuses the existing `doa-sebelum-tidur` content and its
Sahih al-Bukhari 6314 reference. Reading any item does not mark its step
complete. Only the separate checklist control writes completion. Historical
Reader navigation preserves the selected History date and likewise makes no
record write.

Qur'an content is local and split at verse boundaries. Latin transliteration
was cross-checked against the per-verse transliteration published by Qur'an
Kemenag. Indonesian translation follows Qur'an Kemenag's 2019 translation
edition. The Latin text keeps Kemenag's diacritics and pronunciation forms;
local curly apostrophes and a few joined-word hyphens are typography
normalizations. No transliteration wording needed correction in this audit.

Verified transliteration sources:

- Ayat Kursi (`ayat-kursi`), Al-Baqarah 2:255:
  [Qur'an Kemenag, 2:255](https://quran.kemenag.go.id/quran/per-ayat/surah/2?from=255&to=255)
- Al-Ikhlas (`al-ikhlas`), Qur'an 112:1–4:
  [Qur'an Kemenag, Surah 112](https://quran.kemenag.go.id/quran/per-ayat/surah/112?from=1&to=4)
- Al-Falaq (`al-falaq`), Qur'an 113:1–5:
  [Qur'an Kemenag, Surah 113](https://quran.kemenag.go.id/quran/per-ayat/surah/113?from=1&to=5)
- An-Nas (`an-nas`), Qur'an 114:1–6:
  [Qur'an Kemenag, Surah 114](https://quran.kemenag.go.id/quran/per-ayat/surah/114?from=1&to=6)
- Al-Baqarah (`al-baqarah-285-286`), 2:285–286:
  [Qur'an Kemenag, 2:285–286](https://quran.kemenag.go.id/quran/per-ayat/surah/2?from=285&to=286)
- The shared basmala for the three short surahs:
  [Qur'an Kemenag, Surah 1:1](https://quran.kemenag.go.id/quran/per-ayat/surah/1?from=1&to=1)

The Qur'an Kemenag pages show the Arabic text, Latin transliteration, and
Indonesian translation together. The app's `sourceLabel` names the 2019
translation edition; this section records the distinct transliteration source.

Other source references:

- Bedtime dua: Sahih al-Bukhari 6314
- Short three-surah bedtime guidance reference, if shown: Sahih al-Bukhari 5017

The bedtime routine does not track the number of repetitions for Al-Ikhlas,
Al-Falaq, or An-Nas. The Bukhari 5017 guidance is a reference only; it does not
add a completion rule.

## Today, History, and reminders

Today reads the preferred time from the persisted routine definition for
timeline ordering and focus selection. History treats this as an optional
routine: no record means it is absent; recorded Completed, Partial, or Not
Today entries remain visible, including for archived definitions.

The primary reminder uses the persisted preferred time and calmly suggests
preparing the readings and bedtime routine. Penutup Hari uses the standard
actionable routine notification category:

- Done completes all six required steps and leaves Wudu unchanged.
- Snooze uses the existing ten-minute behavior and suppresses that day's
  automatic follow-up.
- Open routes to `/routines/penutup-hari` without writing completion.

An incomplete routine may receive one follow-up one hour after its primary
reminder. Completion and Not Today cancel pending follow-up and snooze
notifications through the existing reminder reconciliation path. Daily
Reflection remains Open-only and is not changed here.

Historical edits write to their selected `CalendarDay` and do not schedule,
cancel, snooze, or reconcile today's operating-system reminders.
