# Localization terminology

Daisth's supported interface languages are Indonesian (`id`) and English
(`en`). Product-facing terminology belongs in presentation localization; stable
routine, step, route, database, and notification payload identifiers remain
unchanged. User-authored content, provider-returned place names, legal/source
text, and verified religious source content are not translated by product
terminology mappings.

## Authoritative glossary

| Concept | Indonesian | English |
| --- | --- | --- |
| Masjid | Masjid | Masjid |
| Mushola | Mushola | Mushola |
| Zikir | Zikir | Zikir |
| Subuh | Subuh | Fajr |
| Dhuha | Dhuha | Duha |
| Zuhur | Zuhur | Dhuhr |
| Asar | Asar | Asr |
| Maghrib | Maghrib | Maghrib |
| Isya | Isya | Isha |
| Sholat Malam | Sholat Malam | Night Prayer |
| Penutup Hari | Penutup Hari | End of Day |

Only **Masjid**, **Mushola**, and **Zikir** are intentionally shared product
terms. Use natural surrounding copy for each locale. Use `Wudu` where natural in
both languages, but it is not a locked shared product term. Translate `Doa`
according to context (usually `Dua` or `Supplication` in English) while keeping
source titles intact.

Use conventional English names for Islamic practices and references where
appropriate (for example `Witr` and `Ayat al-Kursi`). Stable IDs such as
`subuh`, `zuhur`, `asar`, `isya`, `post-prayer-dhikr`, and `penutup-hari` are
internal identity and must never be localized.

Never rewrite user-generated text, external place names, provider-returned
names, legal text, source quotations, Qur'an Arabic, verified translations or
transliterations, hadith quotations, or source metadata. Reader controls and
other Daisth-owned interface chrome can be localized independently from that
source-bound content.
