# Istiqam Asset Pack v1

Prepared for the Istiqam Flutter project.

## Direct-use assets

### Brand
- `assets/brand/istiqam_app_icon_master_1024.png`
- `assets/brand/istiqam_app_icon_master.svg`
- `assets/brand/istiqam_mark_foreground.svg`
- `assets/brand/istiqam_mark_foreground_1024.png`
- `assets/brand/istiqam_icon_background.svg`

The foreground/background split is used for the generated Android adaptive launcher icon.

### Illustrations
- `today_hero.png` — light-theme Today focus-card illustration.
- `today_hero_dark.png` — dark-theme Today focus-card illustration.
- `routine_progress.png` — routine/progress visual.
- `reflection.png` — reflection visual.
- `reader.png` — reading/reader visual.
- `onboarding_scene.png` — onboarding scenic illustration.
- `empty_routines.png`
- `empty_history.png`
- `empty_settings.png`

### Motifs
- `motif_line.png`
- `motif_shape.png`
- `motif_shadow.png`
- `istiqam_line_motif.svg`

## Implementation notes

- These are real project assets, not placeholders.
- Codex should use them from Flutter assets rather than reproducing them with dummy icons.
- The raster illustration files are generated artwork and intentionally use warm cream / muted sage / forest-green styling.
- UI functional icons (navigation, settings, location, etc.) should still use a consistent vector icon system rather than rasterizing icons from a board.
- Do not replace these assets with random stock imagery.
- Additional feature-specific artwork should be prepared and approved before implementation when needed.
