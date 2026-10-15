# Daisth Asset Guide — Asset Pack v3

`assets/README_ASSETS.md` inventories the user-provided Daisth Asset Pack v3.
Use its supplied files as the source for brand treatments; do not recreate the
mark or launcher artwork.

## Brand assets

- Mark: `assets/brand/daisth_mark.png` / `.svg`
- Wordmark: `assets/brand/daisth_wordmark.png` / `.svg`
- Lockup and tagline: `assets/brand/daisth_lockup.png` / `.svg`
- App asset paths: `DaisthAssets` in `lib/core/design_system/assets/`

## Platform assets

- Launcher masters and Android monochrome/notification sources: `assets/launcher/`
- Light and dark launch screens: `assets/splash/`

The launcher icon uses the supplied light master, the adaptive foreground uses
the supplied transparent foreground, and Android uses the provided
monochrome-vector rendering for themed icons plus the separate transparent
notification symbol for its small icon.

## Feature artwork

The 30 app-ready illustrations live in `assets/visuals/3d/` and are registered
through `DaisthAssets`. Only that app-ready set is declared for Flutter runtime
use. The old in-app illustration and empty-state exports were removed after
their replacement call sites were verified. `assets/motifs/` remains as
design reference material and is not bundled at runtime.

Functional interface icons use Phosphor. Do not substitute them with bitmap
brand artwork.
