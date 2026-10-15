# Daisth Full Visual Overhaul — Final Asset Pack Specification

**Basis:** `visual-asset-inventory.md` audit. This specification deliberately expands beyond the audit’s 7 existing 3D-replacement candidates to cover the user-requested full visual overhaul. Inventory facts and design decisions are separated below.

## 1. Source facts from inventory

- 87 physical raster/vector image files were inventoried.
- 75 unique explicit code icon constants were found: 34 Material + 41 Phosphor.
- 7 physical runtime artwork files were originally marked `REPLACE_WITH_3D`.
- Existing brand assets, native launcher/splash/notification assets, third-party branded controls, user photos/attachments, and religious text are special handling / not ordinary 3D replacements.

## 2. Final overhaul policy

- **All visuals are reviewed.** No visual is ignored simply because it is a Flutter/Phosphor icon instead of an image asset.
- **Large/feature visuals:** replace or add 3D artwork.
- **Functional controls:** remain vector for legibility, but the mixed Material/Phosphor system is normalized toward a single Phosphor-led icon language.
- **Material icons are not automatically preserved.** Most become equivalent Phosphor glyphs. Large onboarding Material pictograms are replaced by 3D artwork.
- **Brand/native/third-party:** do not redraw in this pack.
- **Religious Arabic/source text:** never baked into generated artwork.

## 3. Master 3D asset manifest

| ID | Final filename | Surface | Type | Ratio | Master | BG | Theme | Implementation note |
|---|---|---|---|---|---|---|---|---|
| 3D-001 | today_focus_light.png | Today focus card | REPLACE_EXISTING | 16:9 | 4096×2304 | Opaque | Light | Right-weighted hero; low-detail left safe zone for localized copy. |
| 3D-002 | today_focus_dark.png | Today focus card | REPLACE_EXISTING | 16:9 | 4096×2304 | Opaque | Dark | Same camera/composition as 3D-001; true night render, not dimmed light image. |
| 3D-003 | onboarding_intro.png | Onboarding page 1 | REPLACE_EXISTING | 4:3 | 3072×2304 | Alpha/clean cutout | Shared | Centered sculptural scene; no embedded copy. |
| 3D-004 | onboarding_routine.png | Onboarding page 2 | NEW | 1:1 | 2048×2048 | Alpha | Shared | Replaces the large event_available pictogram as the primary visual. |
| 3D-005 | onboarding_calm.png | Onboarding page 3 | NEW | 1:1 | 2048×2048 | Alpha | Shared | Replaces the large spa pictogram as the primary visual. |
| 3D-006 | empty_routines.png | Routines empty state | REPLACE_EXISTING | 4:3 | 3072×2304 | Alpha | Shared | Clear routine/checklist silhouette at 220×190. |
| 3D-007 | routine_editor_header.png | Create/Edit Routine | NEW | 3:2 | 3072×2048 | Alpha | Shared | Quiet compact header/support visual; must not steal vertical space from long form. |
| 3D-008 | routine_attachment_empty.png | Routine editor image section empty state | NEW | 1:1 | 2048×2048 | Alpha | Shared | Small gallery/photo support object; no text. |
| 3D-009 | routine_progress.png | Routine detail 76×76 tile | REPLACE_EXISTING | 1:1 | 2048×2048 | Alpha | Shared | Very simple silhouette; 3–4 large shapes max so it survives 76 px. |
| 3D-010 | routine_detail_support.png | Routine Detail supporting content | NEW | 1:1 | 2048×2048 | Alpha | Shared | Generic calm routine object; secondary to completion UI. |
| 3D-011 | sholat_malam.png | Sholat Malam overview | NEW | 4:3 | 3072×2304 | Alpha | Shared | Night-prayer atmosphere without Arabic/calligraphy/text. |
| 3D-012 | taubat_reading.png | Taubat post-prayer Reader support | NEW | 4:3 | 3072×2304 | Alpha | Shared | Reflective visual only; religious text remains actual app text. |
| 3D-013 | hajat_reading.png | Hajat post-prayer Reader support | NEW | 4:3 | 3072×2304 | Alpha | Shared | Hope/request visual metaphor; no written dua/calligraphy. |
| 3D-014 | reader_header.png | Reader | NEW | 3:2 | 3072×2048 | Alpha | Shared | Book/reading object in Daisth style; controls remain vector. |
| 3D-015 | zikir_counter.png | Zikir counter | NEW | 1:1 | 3072×3072 | Alpha | Shared | Tactile beads/counting-inspired object, no literal sacred text. |
| 3D-016 | zikir_complete.png | Zikir completion | NEW | 1:1 | 2048×2048 | Alpha | Shared | Quiet completion state; not confetti-heavy. |
| 3D-017 | reflection_main.png | Reflection | NEW | 4:3 | 3072×2304 | Alpha | Shared | Journal/quiet water/stone metaphor; no generated writing. |
| 3D-018 | empty_history.png | History empty state | REPLACE_EXISTING | 4:3 | 3072×2304 | Alpha | Shared | Timeline/history silhouette legible at 220×190. |
| 3D-019 | history_summary.png | History populated summary support | NEW | 1:1 | 2048×2048 | Alpha | Shared | Calendar/timeline object; secondary to data. |
| 3D-020 | no_location.png | Masjid & Mushola no-location state | REPLACE_EXISTING | 4:3 | 3072×2304 | Alpha | Shared | Location pin + abstract ground/path; no real map. |
| 3D-021 | mosque_finder_header.png | Masjid & Mushola finder | NEW | 3:2 | 3072×2048 | Alpha | Shared | Location/search atmosphere, restrained Masjid architectural cue. |
| 3D-022 | prayer_location_settings.png | Settings → Prayer & Location | NEW | 1:1 | 2048×2048 | Alpha | Shared | Prayer-time + location concept; compact. |
| 3D-023 | settings_main.png | Settings overview | NEW | 3:2 | 3072×2048 | Alpha | Shared | Abstract organized controls/device objects; no literal gear overload. |
| 3D-024 | notifications_settings.png | Settings → Notifications | NEW | 1:1 | 2048×2048 | Alpha | Shared | Bell/reminder motif; not a replacement for action glyphs. |
| 3D-025 | account_sync.png | Account & Sync | NEW | 1:1 | 2048×2048 | Alpha | Shared | Device/cloud continuity visual; no provider logos. |
| 3D-026 | data_privacy.png | Data & Privacy | NEW | 1:1 | 2048×2048 | Alpha | Shared | Private vault/shield concept; no lock-screen UI text. |
| 3D-027 | auth_signed_out.png | Account signed-out state | NEW | 4:3 | 3072×2304 | Alpha | Shared | Warm account/device visual; Google/Apple buttons remain official controls. |
| 3D-028 | generic_success.png | Shared success/completion states | NEW | 1:1 | 2048×2048 | Alpha | Shared | Generic calm success object for larger empty/status surfaces only. |
| 3D-029 | generic_error.png | Shared recoverable error states | NEW | 4:3 | 3072×2304 | Alpha | Shared | Calm broken-path/error metaphor; no alarming red-heavy art. |
| 3D-030 | coming_soon.png | Shared coming-soon/unavailable states | NEW | 4:3 | 3072×2304 | Alpha | Shared | Unfinished/open-path metaphor; no embedded text. |

### Export rule

- Generate lossless/high-quality PNG masters first.
- App delivery may later use WebP only after visual QA.
- Alpha assets must have clean edges/no halo.
- No embedded words, fake UI text, gibberish, Arabic calligraphy, or provider logos.
- Inspect masters at 100% and 200% before approval. Raster art cannot remain infinitely sharp at arbitrary zoom, so master dimensions are intentionally far above actual app display size.

## 4. Material icon normalization — all 34 explicit Material constants

| Audit ID | Current | Current usage | Final treatment |
|---|---|---|---|
| FUNC-001 | `Icons.access_time` | `lib/features/routines/presentation/routine_editor_screen.dart:754`<br>`lib/features/routines/presentation/routine_editor_screen.dart:858` | MIGRATE_VECTOR → Phosphor clock semantic |
| FUNC-002 | `Icons.account_circle_outlined` | `lib/features/auth/presentation/auth_screens.dart:447` | MIGRATE_VECTOR → Phosphor user-circle semantic |
| ACTION-001 | `Icons.add` | `lib/features/routines/presentation/routine_editor_screen.dart:797` | MIGRATE_VECTOR → Phosphor plus |
| ACTION-002 | `Icons.archive_outlined` | `lib/features/routines/presentation/routine_editor_screen.dart:976` | MIGRATE_VECTOR → Phosphor archive/archive-box semantic |
| ACTION-003 | `Icons.arrow_back` | `lib/features/routines/presentation/routine_editor_screen.dart:693` | MIGRATE_VECTOR → Phosphor arrowLeft |
| FUNC-003 | `Icons.article_outlined` | `lib/features/settings/presentation/settings_detail_screens.dart:875` | MIGRATE_VECTOR → Phosphor article/file-text semantic |
| FUNC-004 | `Icons.check_circle_rounded` | `lib/features/settings/presentation/settings_placeholder_screen.dart:475` | MIGRATE_VECTOR → Phosphor checkCircle |
| ACTION-004 | `Icons.chevron_right_rounded` | `lib/features/settings/presentation/settings_placeholder_screen.dart:246`<br>`lib/features/settings/presentation/settings_placeholder_screen.dart:429`<br>`lib/features/settings/presentation/settings_detail_screens.dart:833`<br>`lib/features/settings/presentation/settings_detail_screens.dart:883`<br>`lib/features/mosque/presentation/screens/mosque_finder_screen.dart:816` | MIGRATE_VECTOR → Phosphor caretRight |
| FUNC-005 | `Icons.circle_outlined` | `lib/features/settings/presentation/settings_placeholder_screen.dart:478` | MIGRATE_VECTOR → Phosphor circle |
| ACTION-005 | `Icons.close` | `lib/features/routines/presentation/routine_editor_screen.dart:1074`<br>`lib/features/routines/presentation/routine_editor_screen.dart:1120` | MIGRATE_VECTOR → Phosphor x |
| FUNC-006 | `Icons.cloud_sync_outlined` | `lib/features/auth/presentation/auth_screens.dart:305` | MIGRATE_VECTOR → Phosphor cloud-sync/cloud-check semantic |
| FUNC-007 | `Icons.delete_outline_rounded` | `lib/features/auth/presentation/auth_screens.dart:532` | MIGRATE_VECTOR → Phosphor trash |
| ACTION-006 | `Icons.directions_walk_rounded` | `lib/features/mosque/presentation/screens/mosque_finder_screen.dart:771` | MIGRATE_VECTOR → Phosphor walking/person-simple-walk semantic |
| FUNC-008 | `Icons.downloading_outlined` | `lib/features/routines/presentation/routine_detail_screen.dart:1064` | MIGRATE_VECTOR → Phosphor download/cloud-arrow-down semantic |
| CAT-001 | `Icons.event_available_rounded` | `lib/features/onboarding/presentation/onboarding_screen.dart:123` | REMOVE_AS_PRIMARY_PICTOGRAM → 3D-004 onboarding_routine; retain a small vector only if a functional row still needs one |
| FUNC-009 | `Icons.event_note_outlined` | `lib/features/settings/presentation/settings_detail_screens.dart:630` | MIGRATE_VECTOR → Phosphor calendar/event-note semantic |
| FUNC-010 | `Icons.history_rounded` | `lib/features/mosque/presentation/screens/mosque_finder_screen.dart:661` | MIGRATE_VECTOR → Phosphor clock-counter-clockwise/history semantic |
| FUNC-011 | `Icons.image_not_supported_outlined` | `lib/features/routines/presentation/routine_detail_screen.dart:1065` | MIGRATE_VECTOR → Phosphor broken-image/image semantic |
| FUNC-012 | `Icons.image_outlined` | `lib/features/routines/presentation/routine_editor_screen.dart:1105` | MIGRATE_VECTOR → Phosphor image |
| FUNC-013 | `Icons.info_outline_rounded` | `lib/features/settings/presentation/settings_placeholder_screen.dart:180`<br>`lib/features/today/presentation/today_screen.dart:474`<br>`lib/features/mosque/presentation/screens/mosque_finder_screen.dart:173`<br>`lib/features/mosque/presentation/screens/mosque_finder_screen.dart:703` | MIGRATE_VECTOR → Phosphor info |
| FUNC-014 | `Icons.location_on_outlined` | `lib/features/settings/presentation/settings_placeholder_screen.dart:83`<br>`lib/features/settings/presentation/settings_detail_screens.dart:296`<br>`lib/features/today/presentation/today_screen.dart:430` | MIGRATE_VECTOR → Phosphor mapPin |
| FUNC-015 | `Icons.location_searching_rounded` | `lib/features/mosque/presentation/screens/mosque_finder_screen.dart:512` | MIGRATE_VECTOR → Phosphor crosshair/location semantic |
| CAT-002 | `Icons.mosque_rounded` | `lib/features/mosque/presentation/screens/mosque_finder_screen.dart:740` | SPECIAL_VECTOR → use a Daisth-consistent mosque glyph; prefer Phosphor equivalent if available, otherwise retain Material only as a documented exception or provide custom SVG |
| FUNC-016 | `Icons.notifications_active_outlined` | `lib/features/settings/presentation/settings_detail_screens.dart:655` | MIGRATE_VECTOR → Phosphor bellRinging semantic |
| FUNC-017 | `Icons.notifications_none_rounded` | `lib/features/settings/presentation/settings_placeholder_screen.dart:108` | MIGRATE_VECTOR → Phosphor bell/bellSimple |
| ACTION-007 | `Icons.open_in_new_rounded` | `lib/features/mosque/presentation/screens/mosque_finder_screen.dart:143` | MIGRATE_VECTOR → Phosphor arrowSquareOut semantic |
| FUNC-018 | `Icons.person_outline_rounded` | `lib/features/settings/presentation/settings_placeholder_screen.dart:132`<br>`lib/features/settings/presentation/settings_detail_screens.dart:818`<br>`lib/features/auth/presentation/auth_screens.dart:569` | MIGRATE_VECTOR → Phosphor user |
| ACTION-008 | `Icons.refresh_rounded` | `lib/features/settings/presentation/settings_detail_screens.dart:282`<br>`lib/features/auth/presentation/auth_screens.dart:392`<br>`lib/features/mosque/presentation/screens/mosque_finder_screen.dart:203`<br>`lib/features/mosque/presentation/screens/mosque_finder_screen.dart:531` | MIGRATE_VECTOR → Phosphor arrowClockwise |
| ACTION-009 | `Icons.restart_alt` | `lib/features/routines/presentation/routine_editor_screen.dart:991` | MIGRATE_VECTOR → Phosphor arrowCounterClockwise |
| FUNC-019 | `Icons.schedule_outlined` | `lib/features/settings/presentation/settings_detail_screens.dart:572` | MIGRATE_VECTOR → Phosphor clock |
| FUNC-020 | `Icons.settings_outlined` | `lib/features/settings/presentation/settings_detail_screens.dart:311`<br>`lib/features/settings/presentation/settings_detail_screens.dart:534` | MIGRATE_VECTOR → Phosphor gear |
| FUNC-021 | `Icons.shield_outlined` | `lib/features/settings/presentation/settings_placeholder_screen.dart:156` | MIGRATE_VECTOR → Phosphor shield/shieldCheck semantic |
| CAT-003 | `Icons.spa_rounded` | `lib/features/onboarding/presentation/onboarding_screen.dart:124` | REMOVE_AS_PRIMARY_PICTOGRAM → 3D-005 onboarding_calm; retain small vector only if functionally necessary elsewhere |
| ACTION-010 | `Icons.sync_rounded` | `lib/features/auth/presentation/auth_screens.dart:322`<br>`lib/features/mosque/presentation/screens/mosque_finder_screen.dart:661` | MIGRATE_VECTOR → Phosphor arrowsClockwise/sync semantic |

**Rule:** Codex must resolve the actual available `phosphor_flutter` constant names in the installed package rather than inventing unavailable constants. Semantics above are the design mapping.

## 5. Existing Phosphor icons — all 41 explicit constants

These are already in the preferred family. They remain vector, but Codex should normalize weight, size, selected state, and color tokens.

| Audit ID | Current | Usage | Final treatment |
|---|---|---|---|
| STATUS-001 | `PhosphorIconsBold.check` | `lib/features/routines/presentation/widgets/routine_steps_card.dart:131` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-001 | `PhosphorIconsFill.calendarCheck` | `lib/app/app_shell.dart:34` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-002 | `PhosphorIconsFill.chartBar` | `lib/app/app_shell.dart:28` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-002 | `PhosphorIconsFill.check` | `lib/core/design_system/components/daisth_status_indicator.dart:20` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-003 | `PhosphorIconsFill.checkCircle` | `lib/features/reflection/presentation/screens/reflection_screen.dart:426` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-003 | `PhosphorIconsFill.gear` | `lib/app/app_shell.dart:40` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-004 | `PhosphorIconsFill.house` | `lib/app/app_shell.dart:22` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-011 | `PhosphorIconsRegular.arrowCounterClockwise` | `lib/features/dhikr/presentation/screens/dhikr_counter_screen.dart:350`<br>`lib/features/dhikr/presentation/screens/dhikr_counter_screen.dart:444` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-012 | `PhosphorIconsRegular.arrowDown` | `lib/features/history/presentation/screens/history_screens.dart:142` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-013 | `PhosphorIconsRegular.arrowLeft` | `lib/features/reader/presentation/screens/reader_screen.dart:71`<br>`lib/features/reader/presentation/screens/reader_screen.dart:186`<br>`lib/features/dhikr/presentation/screens/dhikr_counter_screen.dart:195`<br>`lib/features/dhikr/presentation/screens/dhikr_counter_screen.dart:486`<br>`lib/features/routines/presentation/routine_detail_screen.dart:953` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-014 | `PhosphorIconsRegular.arrowRight` | `lib/features/today/presentation/widgets/focus_routine_card.dart:173` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| FUNC-022 | `PhosphorIconsRegular.bellSimple` | `lib/core/design_system/components/daisth_notice.dart:36` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| CAT-004 | `PhosphorIconsRegular.bookOpenText` | `lib/features/reader/presentation/screens/reader_screen.dart:201`<br>`lib/features/routines/presentation/widgets/routine_link_sections.dart:19`<br>`lib/features/routines/presentation/widgets/routine_sheets.dart:240` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-005 | `PhosphorIconsRegular.calendarCheck` | `lib/app/app_shell.dart:33` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-015 | `PhosphorIconsRegular.caretRight` | `lib/features/routines/presentation/routines_screen.dart:262`<br>`lib/features/routines/presentation/widgets/routine_steps_card.dart:185`<br>`lib/features/routines/presentation/widgets/routine_link_sections.dart:236`<br>`lib/features/history/presentation/screens/history_screens.dart:453`<br>`lib/features/history/presentation/screens/history_screens.dart:496`<br>`lib/features/reflection/presentation/widgets/reflection_today_card.dart:120` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-006 | `PhosphorIconsRegular.chartBar` | `lib/app/app_shell.dart:27` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-004 | `PhosphorIconsRegular.checkCircle` | `lib/core/design_system/components/daisth_notice.dart:32`<br>`lib/features/dhikr/presentation/screens/dhikr_counter_screen.dart:375` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-005 | `PhosphorIconsRegular.circle` | `lib/core/design_system/components/daisth_status_indicator.dart:23`<br>`lib/core/design_system/components/daisth_status_indicator.dart:24`<br>`lib/features/reflection/presentation/screens/reflection_screen.dart:427` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| FUNC-023 | `PhosphorIconsRegular.clock` | `lib/features/today/presentation/widgets/focus_routine_card.dart:149` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-006 | `PhosphorIconsRegular.clockCountdown` | `lib/core/design_system/components/daisth_status_indicator.dart:22` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| FUNC-024 | `PhosphorIconsRegular.deviceMobile` | `lib/features/settings/presentation/settings_placeholder_screen.dart:267` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-016 | `PhosphorIconsRegular.dotsThreeVertical` | `lib/features/dhikr/presentation/screens/dhikr_counter_screen.dart:223`<br>`lib/features/routines/presentation/routine_detail_screen.dart:985` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-017 | `PhosphorIconsRegular.floppyDisk` | `lib/features/reflection/presentation/screens/reflection_screen.dart:345` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-007 | `PhosphorIconsRegular.gear` | `lib/app/app_shell.dart:39` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| CAT-005 | `PhosphorIconsRegular.handsPraying` | `lib/features/dhikr/presentation/screens/dhikr_counter_screen.dart:501`<br>`lib/features/routines/presentation/widgets/routine_link_sections.dart:111` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| NAV-008 | `PhosphorIconsRegular.house` | `lib/app/app_shell.dart:21` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-018 | `PhosphorIconsRegular.image` | `lib/features/routines/presentation/routine_editor_screen.dart:961` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| FUNC-025 | `PhosphorIconsRegular.info` | `lib/core/design_system/components/daisth_notice.dart:33` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-019 | `PhosphorIconsRegular.magnifyingGlass` | `lib/features/routines/presentation/routine_detail_screen.dart:1147` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-020 | `PhosphorIconsRegular.mapPin` | `lib/features/routines/presentation/widgets/routine_link_sections.dart:88` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-007 | `PhosphorIconsRegular.minus` | `lib/core/design_system/components/daisth_status_indicator.dart:21` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-008 | `PhosphorIconsRegular.minusCircle` | `lib/core/design_system/components/daisth_status_indicator.dart:25` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| FUNC-026 | `PhosphorIconsRegular.moon` | `lib/features/settings/presentation/settings_placeholder_screen.dart:277` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| FUNC-027 | `PhosphorIconsRegular.notepad` | `lib/features/reflection/presentation/widgets/reflection_today_card.dart:81` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-021 | `PhosphorIconsRegular.plus` | `lib/features/routines/presentation/routines_screen.dart:145` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| FUNC-028 | `PhosphorIconsRegular.sun` | `lib/features/settings/presentation/settings_placeholder_screen.dart:272` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| CAT-006 | `PhosphorIconsRegular.sunHorizon` | `lib/features/today/presentation/widgets/focus_routine_card.dart:108` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-022 | `PhosphorIconsRegular.trash` | `lib/features/reflection/presentation/screens/reflection_screen.dart:358` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-009 | `PhosphorIconsRegular.warning` | `lib/core/design_system/components/daisth_notice.dart:34` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| ACTION-023 | `PhosphorIconsRegular.x` | `lib/core/design_system/components/daisth_notice.dart:142`<br>`lib/features/reader/presentation/widgets/reader_display_controls.dart:83`<br>`lib/features/routines/presentation/widgets/routine_sheets.dart:190` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |
| STATUS-010 | `PhosphorIconsRegular.xCircle` | `lib/core/design_system/components/daisth_notice.dart:35` | KEEP_PHOSPHOR_VECTOR; normalize token/weight only |

### Phosphor state rules
- Bottom navigation: Regular when inactive, Fill when selected.
- Ordinary actions/navigation: Regular.
- Completion/status: Fill/Bold only when state semantics require stronger emphasis.
- Do not replace 16–24 px functional glyphs with raster 3D assets.
- Avoid arbitrary per-screen icon sizes; use the existing Daisth sizing scale and only normalize inconsistent outliers.

## 6. Package-generated / implicit icons not in the 75 explicit constants

- Flutter Quill toolbar: keep package vector icons; style surrounding toolbar/surface to Daisth. Do not make bold/italic/list/link/undo/redo 3D.
- Implicit Material `BackButton` from nested AppBars: prefer explicit Daisth/Phosphor navigation treatment when touched by the integration pass, but preserve platform navigation semantics.

## 7. Screen → final visual mapping

| Surface | 3D assets | Rule |
|---|---|---|
| Onboarding | 3D-003, 3D-004, 3D-005 | Replace page-1 image; replace page-2/page-3 large flat pictograms with 3D visuals. |
| Today | 3D-001, 3D-002 | Keep code radial glow/gradient as UI treatment; normalize supporting Material glyphs to Phosphor. |
| Routines list | 3D-006 | Keep add/caret/status controls vector. |
| Routine editor | 3D-007, 3D-008 | Long-form editor stays functional; rich-text toolbar and action icons stay vector. |
| Routine detail | 3D-009, 3D-010 | Core progress/completion remains primary; illustration stays secondary. |
| Sholat Malam | 3D-011 | Taubat/Hajat actions remain text/vector controls. |
| Taubat Reader | 3D-012 | Religious Arabic/transliteration/meaning remain text, not pixels. |
| Hajat Reader | 3D-013 | Same content rule; source note remains text. |
| Reader general | 3D-014 | Back/display controls remain vector. |
| Zikir | 3D-015, 3D-016 | Counter/reset/undo remain vector. |
| Reflection | 3D-017 | Save/delete/status remain vector. |
| History | 3D-018, 3D-019 | Timeline/list controls remain vector. |
| Masjid & Mushola | 3D-020, 3D-021 | OSM/map provider visuals and attribution are untouched; navigation/refresh controls remain vector. |
| Settings main | 3D-023 | Rows remain vector-led. |
| Prayer & Location settings | 3D-022 | Supporting illustration only. |
| Notifications settings | 3D-024 | Supporting illustration only. |
| Account & Sync | 3D-025 | No Google/Apple logo generation. |
| Data & Privacy | 3D-026 | Supporting illustration only. |
| Auth signed-out | 3D-027 | Official auth controls untouched. |
| Shared success | 3D-028 | Use only on larger success surfaces, not every checkmark. |
| Shared error | 3D-029 | Use on substantial recoverable error/empty surfaces; small inline errors remain vector/text. |
| Coming soon/unavailable | 3D-030 | Reusable large state art. |

## 8. Brand / native / third-party / user-content handling

- Daisth mark, wordmark, lockup: keep approved geometry.
- App icon/adaptive icon/splash/notification small icon: separate native pass.
- Apple Sign In control: keep official package rendering.
- Google auth: do not invent a logo.
- OSM attribution/provider visuals: preserve.
- User routine attachment images and account photos: never restyle or regenerate.
- Plus Jakarta Sans and its OFL license: preserve.

## 9. Legacy asset cleanup candidates — only after integration + physical QA

Do not delete before the new visuals are integrated and referenced. Re-audit these later: unused mosque hero pair, old reader/reflection illustrations, unused empty-state PNG/SVG pairs, unused motif SVGs, and any superseded runtime illustration files. Brand/native/reference assets require separate review and are not generic cleanup targets.

## 10. Production order

1. Today hero pair.
2. Onboarding trio.
3. Routine family.
4. Sholat Malam + Taubat + Hajat + Reader.
5. Zikir + Reflection + History.
6. Masjid/Location.
7. Settings/Auth family.
8. Shared success/error/coming-soon states.
9. Integration + icon normalization.
10. Physical-device visual QA.
11. Dead-asset cleanup.

## 11. Approval gate before generation

This spec is the blueprint. Generation should not start until the product owner accepts the 30-asset scope and the icon-normalization policy. Once approved, generated outputs must be individual standalone files, never contact sheets, with a final ZIP containing masters, app-ready files, and a mapping manifest.
