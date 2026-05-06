# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build for simulator
xcodebuild -project LipersFree.xcodeproj -scheme LipersFree \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all tests
xcodebuild test -project LipersFree.xcodeproj -scheme LipersFree \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test
xcodebuild test -project LipersFree.xcodeproj -scheme LipersFree \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:LipersFreeTests/LipersFreeTests/testExample
```

## Architecture

MVVM with SwiftUI. The app is locked to dark mode (`.preferredColorScheme(.dark)` on the root `TabView`).

### Navigation flow

```
ContentView (TabView)
├── Explore tab → ExploreView → CategoryDetailView → WallpaperDetailView
├── Maker tab   → MakerView   (stub)
└── Settings tab → SettingsView (stub)
```

`RootTabViewModel` owns the selected tab. Each tab is wrapped in its own `NavigationStack` in `ContentView`.

### Data layer

`APIService` (singleton at `.shared`) is the sole network layer. It uses `async/await` with a generic `performRequest<T: Decodable>` method. Base URL: `https://liper.codecrew360.xyz/api/v1`.

- `GET /home` → `HomeResponse` (`[HomeSection]` + pagination meta)
- `GET /wallpapers?category_id=&page=` → `WallpaperResponse` (`[Wallpaper]` + pagination meta)

ViewModels accept an optional `APIService` parameter for injection in tests.

### Key patterns

- **ExploreViewModel**: fetches `/home` once (`hasLoaded` guard), exposes sections and a computed `categories` array.
- **CategoryDetailViewModel**: handles paginated wallpaper loading. `loadMoreIfNeeded(currentItem:)` triggers the next page when the item is within 4 positions of the end.
- **WallpaperDetailView**: streams `Wallpaper.file_url` via `AVPlayer` (video), loops via `AVPlayerItemDidPlayToEndTime`. "Set Wallpaper" and "Download" actions are TODO stubs.

### Theming

`AppThemeService.screenBackground` (`.purple`) is the background for top-level screens. `PrimaryScreenContainer` applies this background and hides the navigation bar — use it for all primary tab screens. Detail views use plain `.black`.

`WallpaperCardView` renders a `preview_image` thumbnail (static image) with a crown badge for `is_premium` wallpapers. The actual wallpaper content is always video (`file_url`).
