# Project context

Istiqam is a calm Muslim routine companion that supports consistency in daily
worship through a loop of routine, reminder, action, completion, reflection,
and insight. Its visual direction is warm minimal: quiet, supportive, and
grounded, with spiritually subtle details.

The application is built with Flutter and targets Android first while retaining
the generated iOS project. It is intended to support multiple users in a later
stage. Firebase is planned for later, after the initial product foundation.

This first implementation includes a Material 3 light and dark theme, reusable
design system components, a four destination app shell, and a static Today
screen. The Today sample displays routine progress, a next routine focus card,
a timeline, a daily reflection, and a day closing entry.

There is no Firebase integration, authentication, prayer-time calculation,
notification scheduling, or persisted routine state in this scope. History,
Routines, and Settings are presentation placeholders. Mosque Finder is the
first network-backed feature: it uses OpenStreetMap data through the public
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
