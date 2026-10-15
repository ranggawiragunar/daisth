# Daisth Asset Pack v3

Production-oriented brand assets prepared from the approved Daisth direction.

## Brand
- `brand/daisth_mark.svg` and `.png`: primary mark on transparent background.
- `brand/daisth_wordmark.svg` and `.png`: Daisth wordmark.
- `brand/daisth_lockup.svg` and `.png`: mark + wordmark + tagline.

## Launcher
- `launcher/app_icon_light.png`: square 1024 px launcher master, no transparency.
- `launcher/app_icon_dark.png`: square 1024 px dark launcher master, no transparency.
- `launcher/app_icon_monochrome.png`: monochrome preview/master.
- `launcher/daisth_foreground.png`: transparent adaptive foreground master (1080 px).
- `launcher/daisth_monochrome.svg`: single-color Android adaptive monochrome source.
- `launcher/daisth_notification_small.png/.svg`: Android small notification icon, white-on-transparent source.

## Splash
- `splash/splash_light.png` 1242×2688.
- `splash/splash_dark.png` 1242×2688.

## Feature artwork
- `visuals/`: 30 approved app-ready PNGs used by Today, onboarding, routines,
  Reader, Zikir, Reflection, History, location, Settings, Account, and shared
  states. Their semantic names and call sites are centralized in
  `DaisthAssets`.
- The app-ready PNGs are the only 3D artwork declared in Flutter's runtime
  bundle. Source masters are not included in the runtime asset set.

## References
- `references/daisth_brand_board.png`: approved direction board.
- `references/tagline_reference.png`.
- `references/palette.txt`.

## Design references
- `motifs/`: retained SVG design references; they are not included in the
  Flutter runtime bundle.
- `references/`: approved direction board, asset preview, palette, and tagline
  reference; documentation only.

Notes:
- Superseded in-app 2D illustrations and empty-state exports were removed
  after the 3D replacements were wired and verified.
- Android/iOS final generated launcher resources should be produced from these masters by the existing Flutter tooling.
- Notification small icon is intentionally monochrome/white-on-transparent to satisfy Android system rendering.
