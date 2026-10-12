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
notification scheduling, location support, network access, or persisted routine
state in this scope. History, Routines, and Settings are presentation
placeholders.

The Zuhur Routine Detail includes an optional post-prayer dhikr session. It
guides the user through 33 Subhanallah, 33 Alhamdulillah, 33 Allahu Akbar, and
one closing tahlil, with automatic advancement between items. Completion is
returned to Routine Detail; unfinished session progress remains temporary.
