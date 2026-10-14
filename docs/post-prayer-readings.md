# Post-prayer readings in Sholat Malam

The Sholat Malam **Bacaan Zikir & Sholawat** section contains exactly two
read-only Reader entries:

1. `taubat-after-prayer` — Istighfar and Sayyidul Istighfar.
2. `hajat-after-prayer` — Pujian & Sholawat and Doa Hajat.

They are static `ReaderContentCatalog` entries. The Arabic, transliteration,
Indonesian meaning, and English meaning are bundled as source-controlled text;
they are not routine notes, database rows, image attachments, or sync data.
Opening either entry is navigation only and never marks a routine or step
complete.

The Sayyidul Istighfar wording is referenced to
[Sahih al-Bukhari 6306](https://sunnah.com/bukhari/80/3). The selected Doa Hajat
wording is referenced to
[Jami' at-Tirmidhi 479](https://sunnah.com/tirmidhi/3/27); its Reader note says
that the narration's chain has noted weakness. It is not presented as
unanimously sahih. The Pujian & Sholawat text follows the user's supplied
reference and has no hadith/source or authenticity claim in the app.

The prior Sholat Malam-only `doa-sebelum-tidur` route mapping was removed. The
bedtime reading itself remains registered under Penutup Hari. Tahajud and
Witir remain required Sholat Malam steps; only their old supporting guidance
cards were removed.
