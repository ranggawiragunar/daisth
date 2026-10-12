# Design system

## Principles

- The visual direction is **Warm Minimal + Quiet Depth**: warm neutral color,
  restrained tonal layers, editorial spacing, and subtle borders. Avoid generic
  Material surfaces, heavy shadows, and decorative Islamic template motifs.
- Use warm off-white and muted green in light mode, with deep green-black
  surfaces in dark mode.
- Keep hierarchy clear through spacing, type, and subtle borders rather than
  shadows or decorative motifs.
- Present routine state with an icon and semantic color. An unrecorded routine
  is neutral and never communicates failure.
- Use Plus Jakarta Sans through `google_fonts`, configured centrally in
  `IstiqamTypography`. The font provider can later be switched to local font
  assets without changing feature widgets. An Arabic reader typeface remains
  reserved and undecided.

## Color

Light semantic colors live in `IstiqamColors`: background `#F7F6F2`, surface
`#FFFFFF`, secondary surface `#F1F0EB`, primary text `#202321`, secondary text
`#666B67`, border `#E4E4DE`, and brand green from `#1E3A34` through `#5A8878`.
Warm accent colors are `#8A654C`, `#B18768`, and `#F1E7DE`.

Dark mode uses background `#111815`, surface `#19221E`, secondary surface
`#202B26`, primary text `#F2F1EC`, secondary text `#B3B8B3`, and a soft green
primary `#8DB5A5`. `IstiqamThemeExtension` holds borders, surfaces, and the
status palette for both themes.

## Spacing and radius

Spacing uses a 4px base scale: 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, and 64px.
Screens use 20px horizontal padding, major sections use 32px separation, and
content is limited to 640px on wide layouts.

Radii are 8, 12, 16, and 20px, plus a pill token for small indicators. Buttons
and standard surfaces use 16px; focus surfaces use 20px.

## Typography, icons, and components

`IstiqamTypography` defines the display, title, body, and label styles in Plus
Jakarta Sans. Visible application icons use the `phosphor_icons` package, with
regular weight for contextual and inactive icons and fill weight for selected
navigation and completion states.

`IstiqamButton`, `IstiqamSurface`, `IstiqamProgressBar`,
`IstiqamSegmentedProgress`, `IstiqamStatusIndicator`, and `IstiqamEmptyState`
provide reusable foundations. Today uses seven quiet segments for routine
progress, filling recorded routines with the brand green.

Status colors and icons distinguish completed, partial, due, upcoming,
unrecorded, and not scheduled today. The palette adapts for dark mode.

## Hero art, timeline, and assets

Today's focus card selects the approved `today_hero.png` or
`today_hero_dark.png` to match the active theme, as a clipped, right-weighted
background layer with a left text scrim. The timeline keeps
completed entries compact, gives the next routine a sage highlight and ring
node, and softens upcoming connectors. The current timeline state and card use
tonal surfaces instead of separate elevated cards.

Use only approved assets from `assets/`. Do not draw, generate, or substitute
product illustrations. Register the raster illustration and motif assets in
`pubspec.yaml`; no runtime SVG renderer is used. The approved visual-direction
board informed the hero composition, timeline emphasis, segmented progress,
warm atmosphere, and navigation. Empty History, Routines, and Settings use
their approved project illustrations.
