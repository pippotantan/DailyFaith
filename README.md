# DailyFaith

DailyFaith turns your lock screen and home screen into a daily dose of Scripture. It pairs a random Bible verse with a beautiful background image, then generates a wallpaper you can set manually or have updated automatically on a schedule.

## Features

### Verse Wallpapers
- **Daily verse wallpapers** — Random verse over a high-quality background, with readable text and dark overlay for contrast.
- **Verse by topic** — Filter verses by keyword: All (66 books), Love, Strength, Hope, Peace, Faith, Comfort, Wisdom, Grace, or Joy.
- **Offline verses** — 100+ verses are stored locally so the app can show random verses even without an internet connection.

### Background Images
- **Pexels (online)** — High-quality images from Pexels API. Filter by keyword: All, Nature, Christian, Animals, Wildlife, Outer Space, Landscape, Sky, Ocean, Mountains, or Flowers.
- **Device gallery (offline)** — Select multiple images from your gallery. The app picks one randomly for each background. Works fully offline.
- **Background source** — Choose Pexels or your gallery in Wallpaper Settings. When offline, Pexels automatically falls back to local gallery if available.
- **Pexels attribution** — Photographer credit shown at the bottom when using Pexels images.

### Customization
- **Font size, alignment, color** — Adjust how the verse appears on the wallpaper.
- **Font family** — Roboto, Playfair Display, or Great Vibes.
- **Use for daily** — Apply your editor settings to scheduled wallpapers.
- **Apply where** — Lock screen only, home screen only, or both (via Wallpaper Settings).

### Wallpaper Updates
- **Manual** — Set the current verse + image as your wallpaper with one tap.
- **Scheduled** — Daily refresh at a time you choose (e.g. each morning). Uses WorkManager for reliable background execution.
- **Capture preview** — Save the current design as an image without setting it as wallpaper.

### Offline Support
- **Works offline** — With local gallery images selected, the app can update wallpapers without internet. Offline verses are pre-loaded for all topics.
- **Scheduled updates offline** — Daily wallpaper tasks run even when the device is offline, using local images and verses.

## Requirements

- Flutter SDK ^3.9.2 (see `pubspec.yaml`)
- Android (tested); iOS and other platforms may need configuration
- Network access for verses and images (when using online sources)
- Permissions: wallpaper, storage/media (for setting wallpaper and gallery), notifications and exact alarm (for scheduled updates)

## Getting Started

1. Clone the repo and open the project.
2. Run `flutter pub get`.
3. Run the app: `flutter run`, or build a release APK: `flutter build apk --release`.

## Project Structure

- `lib/features/` — Main UI: verse screen, editor controls, wallpaper settings.
- `lib/core/services/` — Background provider, Bible API, verse repository, Pexels, local gallery, image generation, wallpaper, WorkManager, settings.
- `lib/core/data/` — Offline verse store.
- `lib/core/models/` — Bible verse, background source, background result.
- `lib/core/utils/` — Bible metadata (66 books), topics, background keywords.
- `lib/background/` — WorkManager callback for scheduled wallpaper updates.

## License

Private project; not published to pub.dev.
