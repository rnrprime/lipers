# LipersFree — Dev Journal

---

## Session 1 — 2026-05-05

### What we built

**Color Palette**
- Replaced flat purple `#1A0533` with dark navy `#141824` as primary background
- Accent: `#9B5CF6` (vivid violet), gradient to `#C084FC`
- Full palette defined in `AppThemeService` with `Color(hex:)` extension

**API Alignment**
- Mapped all 4 backend endpoints: `/home`, `/categories`, `/wallpapers`, `/wallpapers/{id}`
- `Wallpaper` model: added optional `live_image_url`, `live_video_url`, `category`
- `WallpaperResponse`: proper `WallpaperMeta` (full fields) + `WallpaperLinks`
- `APIService`: added `fetchCategories()`, `fetchWallpaper(id:)`, made `categoryId` optional

**Explore Screen**
- Replaced section-based layout with 2-column infinite scroll grid
- Category filter chips with circular thumbnail + name (horizontal scroll)
- `ExploreGridViewModel`: parallel fetch of categories + wallpapers, pagination, category filtering
- `livephoto` SF Symbol badge on every wallpaper card
- Loading, error (with retry), and empty states

**Wallpaper Detail Screen**
- Full-screen video via custom `VideoPlayerView` (AVPlayerViewController, no controls)
- X dismiss button top-right
- 3 circular action buttons: Set Wallpaper (left, 52pt), Download (center, 68pt), Favorite (right, 52pt)
- Horizontal thumbnail strip at bottom — fetches related wallpapers by category, tapping switches video
- `LivePhotoService`: downloads `.jpg` + `.mov` in parallel, saves as native Live Photo via `PHAssetCreationRequest`
- `SetWallpaperInstructionsView`: 6-step sheet shown after saving
- Toast system (`ToastView`) for success/error feedback

**Settings Screen (UI only)**
- Go Pro gradient banner with decorative circles, crown badge, CTA button
- Account section: Restore Purchases
- Preferences section: Set Wallpaper To — segmented picker (Home / Lock / Both)
- About section: Rate App, Share App, Privacy Policy, Terms of Use
- App section: version from `Bundle.main`

### Key decisions

| Decision | Reason |
|---|---|
| Server pre-pairs `.jpg` + `.mov` for Live Photos | Avoids on-device Content Identifier injection complexity |
| On-device pairing kept for Maker tab | User-created wallpapers need client-side pairing |
| `live_image_url` / `live_video_url` optional in model | API doesn't return them yet — fields are planned backend addition |
| Dark navy background over purple | Matches reference UI, more professional and premium feel |
| `ExploreGridViewModel` replaces `ExploreViewModel` | Grid + filter UX is better than section-based scroll |

### Backend work needed
- Add `live_image_url` and `live_video_url` to all wallpaper API responses
- Files must be server-paired (matching Content Identifiers in JPEG EXIF + MOV metadata)
- File format: `.jpg` (not PNG) and `.mov` (not MP4) for Live Photo compatibility

---

### Pending features (in priority order)

- [ ] **Favorites** — heart button on cards, SwiftData persistence, section in Explore
- [ ] **Paywall / StoreKit 2** — `PremiumService`, paywall sheet, gate premium wallpapers
- [ ] **Search** — search bar in Explore, debounced query, results grid
- [ ] **Maker tab** — pick video + image from Photos, inject Content ID on-device, preview, save
- [ ] **Onboarding** — 3-screen carousel, shown once on first launch

---

## Session 2 — 2026-05-06

### What we built

**Live Wallpaper Maker (full 3-step wizard)**

**`Services/LivePhotoCreator.swift`** (new)
- `createAndSave(videoURL:frameTime:)` — end-to-end pipeline: extract frame → write JPEG with Content ID → re-export MOV with Content ID → save as Live Photo
- JPEG: `CGImageDestination` + `kCGImagePropertyMakerAppleDictionary` key `"17"` (Apple Live Photo EXIF tag)
- MOV: `AVAssetExportSession` with `AVAssetExportPresetPassthrough` (no re-encode, fast) + `AVMutableMetadataItem` for `com.apple.quicktime.content.identifier` in `quickTimeMetadata` keyspace
- Save: same `PHAssetCreationRequest` / `.pairedVideo` pattern as `LivePhotoService`
- `extractFrame(from:at:)` exposed publicly for preview generation

**`ViewModels/MakerViewModel.swift`** (new)
- Uses `@Observable` (not `ObservableObject`) — required for Swift 6 / iOS 26 target
- `Step` enum: `.landing`, `.frameSelection(videoURL:)`, `.preview(videoURL:frameTime:still:)`
- `videoSelected`, `framePicked`, `goBack`, `save` drive step transitions with `withAnimation`

**`Views/MakerView.swift`** (rewrite)
- `MakerView`: root `ZStack` switching on `vm.step.index` with `.easeInOut` animation, toast overlay
- `MakerLandingView`: header, gradient "+" hero button, "How It Works" 3-step card

**`Views/Maker/VideoPicker.swift`** (new) — `PHPickerViewController` wrapper; copies the ephemeral system-provided URL to a persistent temp file before handing it to the caller

**`Views/Maker/MakerFrameStepView.swift`** (new)
- Frame preview card (300 pt tall, fills width)
- `VideoScrubberView` with 80 ms debounce (`Task` cancel-and-restart pattern)
- `AVAssetImageGenerator` stored in `init` to avoid repeated allocation
- Back / "Use This Frame" action row

**`Views/Maker/MakerPreviewStepView.swift`** (new)
- Tap to toggle still ↔ video (play/pause circle overlay)
- Live Photo badge
- Back / "Save to Photos" row; spinner while saving

**`Views/Shared/ButtonStyles.swift`** (new) — `PrimaryButtonStyle` (gradient), `SecondaryButtonStyle` (glass)

**`Views/Shared/VideoScrubberView.swift`** (new) — `Slider` + time labels (current / total)

**`Views/Maker/MakerStepHeader.swift`** (new) — reusable title + subtitle block for step views

### Key decisions

| Decision | Reason |
|---|---|
| `@Observable` instead of `ObservableObject` | Swift 6 strict concurrency rejects `@MainActor` + `@Published` synthesis |
| `AVAssetExportPresetPassthrough` for MOV | No re-encode — just rewraps the container with metadata; fast on any device |
| 80 ms debounce on frame extraction | Prevents hammering `AVAssetImageGenerator` while scrubbing |
| `PHPickerViewController` (no permission required) | System picker handles privacy; app only needs `.addOnly` for saving |
| Copy PHPicker URL in handler | System URL is only valid inside the `loadFileRepresentation` callback |

---

### Pending features (in priority order)

- [ ] **Favorites** — heart button on cards, SwiftData persistence, section in Explore
- [ ] **Paywall / StoreKit 2** — `PremiumService`, paywall sheet, gate premium wallpapers
- [ ] **Search** — search bar in Explore, debounced query, results grid
- [ ] **Maker enhancements** — video trim slider, recent creations gallery
- [ ] **Onboarding** — 3-screen carousel, shown once on first launch
