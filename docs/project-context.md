# Project context

Istiqam is a calm Muslim routine companion that supports consistency in daily
worship through a loop of routine, reminder, action, completion, reflection,
and insight. Its visual direction is warm minimal: quiet, supportive, and
grounded, with spiritually subtle details.

The application is built with Flutter and targets Android first while retaining
the generated iOS project. It is intended to support multiple users in a later
stage. Firebase is planned for later, after the initial product foundation.

The app includes a Material 3 light and dark theme, reusable design system
components, and a four destination app shell. Today calculates daily prayer
times locally with the Indonesia (KEMENAG) method and Shafi Asr, using current
foreground device location. It displays the five mandatory prayer times,
preferred times for Dhuha and Sholat Malam, a prayer focus card, routine
progress, daily reflection, and day closing entry. Settings shows the current
prayer and location configuration, and all five mandatory prayer details can
reuse the same post-prayer dhikr sequence.

There is no Firebase integration, authentication, notification scheduling, or
persisted routine state in this scope. Prayer calculations run on device using
`adhan_dart`; there is no runtime Kemenag API call, background location, or
persistent coordinate storage. The flow uses automatic current-device location
and device-local time formatting, assuming the device timezone matches its
physical location. Manual remote-location selection and coordinate-to-timezone
lookup are future scope. History and Routines remain presentation placeholders.
Mosque Finder uses OpenStreetMap data through the public
Overpass API for MVP proximity discovery. Searches expand from 1.5 km to 3 km
and then 5 km when fewer than six places are found, and the UI caps results at
20. The public Overpass service is not assumed to be permanent production
infrastructure; at significant scale, evaluate a replacement, proxy, or
self-hosted service. Display visible OpenStreetMap attribution wherever its
place data is shown. Location is foreground-only and session-only, with no
location or search-history persistence.

The Zuhur Routine Detail includes an optional post-prayer dhikr session. It
guides the user through 33 Subhanallah, 33 Alhamdulillah, 33 Allahu Akbar, and
one closing tahlil, with automatic advancement between items. Completion is
returned to Routine Detail; unfinished session progress remains temporary.
