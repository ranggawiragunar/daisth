# App Store listing draft

**Status: draft only; not submitted.** Text below is a starting point for an Indonesian-market listing. Verify limits, availability, category, and localization in App Store Connect.

- **Name:** Daisth
- **Subtitle draft:** Muslim routines & prayer
- **Promotional text draft:** A calm companion for prayer times, daily routines, reflection, and nearby mosques.
- **Description draft:**

  Daisth is a calm Muslim routine companion designed to help you stay consistent in what matters.

  Plan and record daily routines, view your history, read curated Qur'an and dhikr references, and add a private daily Reflection. Prayer schedules are calculated for your location. Local reminders can help you return to the routines you choose.

  Find nearby mosques with OpenStreetMap data and open directions in Google Maps. Location is processed on your device for prayer calculations; nearby search sends coordinates to an OpenStreetMap/Overpass service. Choosing directions sends the selected destination to Google Maps.

  The core app works without an account. If you choose to sign in and separately activate sync, selected routines, history, and Reflection data sync to private Firebase/Firestore storage under your account. Local data remains on this device if you delete your account.

  Daisth is observational and personal: no streak scores, rankings, or pressure to complete every routine.

- **Keywords draft (<=100 bytes after localization):** muslim,prayer,routine,dhikr,mosque,reflection
- **Primary category recommendation:** Lifestyle (confirm Apple's available category and best fit in App Store Connect).
- **Review notes draft:** Account creation is optional; core features work signed out. On iOS, Google sign-in is available and Sign in with Apple is implemented subject to production configuration. Cloud sync requires explicit activation after sign-in. Location is used locally for prayer calculation and sent to Overpass for nearby mosque searches. Reminders are scheduled locally. Delete Account appears under Settings → Account / Data & Privacy in the signed-in account screen. **USER INPUT REQUIRED — reviewer test-account/access strategy** if review needs linked cloud data. Do not paste real credentials here.
- **Support URL / Privacy Policy URL:** USER INPUT REQUIRED. No fake URLs.
- **App Review contact / developer identity:** USER INPUT REQUIRED.
- **Screenshots:** capture genuine screenshots from final signed iPhone and any required iPad sizes; do not fabricate.
- **Age rating:** answer App Store Connect's current age-rating questionnaire truthfully; no official rating assigned in this draft.

Apple's currently documented limits include promotional text 170 characters, description 4,000 characters, keywords 100 bytes, and subtitle 30 characters; confirm all fields in the current App Store Connect UI before submission. See [Product Page guidance](https://developer.apple.com/app-store/product-page/) and [field reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
