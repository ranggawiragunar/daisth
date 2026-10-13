# Modern Alert / Toast Direction

Daisth should not use raw/default-looking snackbars for product feedback.

Use a reusable floating in-app alert component with:
- rounded container (about 16px)
- surface/tonal background
- subtle border and restrained shadow
- leading Phosphor status icon
- compact title + optional supporting text
- optional trailing action or close
- smooth 180–260ms enter/exit animation
- light haptic only for meaningful success/error feedback

Semantic variants:
- success
- info
- warning
- error
- neutral

Examples:
- “Zuhur recorded” + optional `Start Dhikr`
- “Routine updated”
- “Prayer times use your last known location” + `Refresh`
- “Feature coming soon”

Avoid platform-style toast rectangles and default Material snackbar appearance.
