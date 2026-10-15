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
  `DaisthTypography`. The font provider can later be switched to local font
  assets without changing feature widgets. An Arabic reader typeface remains
  reserved and undecided.

## Color

Light semantic colors live in `DaisthColors`: background `#F7F6F2`, surface
`#FFFFFF`, secondary surface `#F1F0EB`, primary text `#202321`, secondary text
`#666B67`, border `#E4E4DE`, and brand green from `#1E3A34` through `#5A8878`.
Warm accent colors are `#8A654C`, `#B18768`, and `#F1E7DE`.

Dark mode uses background `#111815`, surface `#19221E`, secondary surface
`#202B26`, primary text `#F2F1EC`, secondary text `#B3B8B3`, and a soft green
primary `#8DB5A5`. `DaisthThemeExtension` holds borders, surfaces, and the
status palette for both themes.

## Spacing and radius

Spacing uses a 4px base scale: 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, and 64px.
Screens use 20px horizontal padding, major sections use 32px separation, and
content is limited to 640px on wide layouts.

Radii are 8, 12, 16, and 20px, plus a pill token for small indicators. Buttons
and standard surfaces use 16px; focus surfaces use 20px.

## Typography, icons, and components

`DaisthTypography` defines the display, title, body, and label styles in Plus
Jakarta Sans. Visible application icons use the `phosphor_icons` package, with
regular weight for contextual and inactive icons and fill weight for selected
navigation and completion states.

`DaisthButton`, `DaisthSurface`, `DaisthProgressBar`,
`DaisthSegmentedProgress`, `DaisthStatusIndicator`, and `DaisthEmptyState`
provide reusable foundations. Today uses seven quiet segments for routine
progress, filling recorded routines with the brand green.

Status colors and icons distinguish completed, partial, due, upcoming,
unrecorded, and not scheduled today. The palette adapts for dark mode.

## Hero art, timeline, and assets

Today's focus card selects `DaisthAssets.todayFocusLight` or
`DaisthAssets.todayFocusDark` to match the active theme, as a clipped, right-weighted
background layer with a left text scrim. The timeline keeps
completed entries compact, gives the next routine a sage highlight and ring
node, and softens upcoming connectors. The current timeline state and card use
tonal surfaces instead of separate elevated cards.

Use the approved app-ready illustrations in `assets/visuals/3d/` through
`DaisthAssets`. Do not draw, generate, or substitute product illustrations.
Only app-ready PNGs are included in Flutter's runtime asset bundle; design
references remain outside it. No runtime SVG renderer is used.

### 3D artwork

The runtime 3D set contains 30 app-ready PNGs registered in `DaisthAssets` and
declared under `assets/visuals/3d/`. Preserve source fidelity and aspect ratio.
Prominent artwork uses `FilterQuality.high` and, where suitable, anti-aliased
clipping. The Today hero uses the light or dark source selected by the active
theme. Small functional glyphs remain Phosphor vectors.

### Transient notices

`DaisthNotice` and `DaisthNoticeController` provide the reusable floating
notice for transient feedback. Notices support success, info, warning, error,
and neutral semantic variants, each with a tonal theme-aware surface and a
Phosphor icon. A notice can include supporting text, an action, and a close
button. The controller presents one notice at a time below the top safe area,
allows the rest of the app to remain interactive, and uses a brief fade/slide
animation with reduced-motion handling. Notices without an action dismiss after
four seconds by default; action notices remain visible until acted on or closed.

Use this notice system for product feedback. Do not introduce default Material
SnackBars or toast styling in the implemented app UI.
