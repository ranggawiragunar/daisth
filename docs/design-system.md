# Design system

## Principles

- Use warm off-white and muted green in light mode, with deep green-black
  surfaces in dark mode.
- Keep hierarchy clear through spacing, type, and subtle borders rather than
  shadows or decorative motifs.
- Present routine state with an icon and semantic color. An unrecorded routine
  is neutral and never communicates failure.
- Keep the system font for now. Typography tokens centralize future typeface
  choices, including a reserved Arabic reader typeface path.

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

## Typography and components

`IstiqamTypography` defines the display, title, body, and label styles. It uses
the platform sans font with no font package. `IstiqamButton`, `IstiqamSurface`,
`IstiqamProgressBar`, and `IstiqamStatusIndicator` provide the reusable
foundations used by Today.

Status colors and icons distinguish completed, partial, due, upcoming,
unrecorded, and not scheduled today. The palette adapts for dark mode.
