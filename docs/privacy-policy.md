# Privacy Policy — DailyFaith (Bible Wallpaper)

**Last updated:** September 13, 2026  
**App name:** DailyFaith  
**Developer / project:** Zane Daily Faith  
**Android application ID:** `com.zanedailyfaith.biblewallpaper`

This Privacy Policy describes how the DailyFaith mobile application (“the App”) handles information when you use it. The App is free to use and does not require an account.

---

## Summary

DailyFaith runs primarily on your device. It does not operate its own user accounts or payment processing. Optional support donations open an external Buy Me a Coffee page in your browser. The App may contact third-party services (Pexels and Bible verse API) when you use online features.

---

## Information the App Uses

### 1. Information stored on your device

The App stores preferences locally using Android SharedPreferences and app-private storage, including:

- Wallpaper editor settings (font size, color, alignment, font family)
- Wallpaper target (lock screen, home screen, or both)
- Background source (Pexels or local gallery)
- Selected background keyword and verse topic
- Paths to images you choose from your gallery (copies saved in app storage for reliable access)
- Scheduled daily wallpaper time, if you enable scheduling

This data stays on your device unless you uninstall the App or clear app data.

### 2. Photos and media you select

If you choose **local gallery** backgrounds, the App uses the system photo picker to let you select images. Selected images may be copied into the App’s private storage so backgrounds work offline and in background tasks. The App does not upload your gallery images to a server operated by Zane Daily Faith.

If you use **capture/save** features, generated wallpaper images may be saved to your device’s Pictures folder with your permission.

### 3. Network and third-party services

When online features are used, the App may send requests to:

| Service | Purpose | Data sent |
|---------|---------|-----------|
| **Pexels API** (`api.pexels.com`) | Fetch stock background photos | Search query keywords; API authentication header from app configuration; standard HTTP metadata |
| **labs.bible.org API** | Fetch Bible verse text | Bible passage reference for the requested verse; standard HTTP metadata |

The App does not send your name, email, or account credentials to these services. Third-party services have their own privacy policies.

### 4. Generated wallpapers

The App creates wallpaper images on your device combining verse text and a background. These files are stored locally (for example in app documents storage) when you set or schedule wallpapers. They are not transmitted to Zane Daily Faith servers.

### 5. Support link (Buy Me a Coffee)

If you tap **Buy Me a Coffee** in settings, the App opens `https://buymeacoffee.com/zane.daily.faith` in your external browser. The App does not process payments or collect payment information. Any information you provide on Buy Me a Coffee is governed by Buy Me a Coffee’s policies.

### 6. Privacy policy link

If configured for your build, the App can open a hosted copy of this policy in your browser via **Privacy Policy** in settings.

---

## Information We Do Not Collect

The App, as provided by Zane Daily Faith, does **not**:

- Require user registration or login
- Collect payment or financial information inside the App
- Track whether you donated
- Use in-app analytics or advertising SDKs (none are integrated in the current App)
- Knowingly collect personal information from children through dedicated profile features (the App has no accounts)

---

## Permissions

The App may request Android permissions needed for its features, such as:

- **Internet** — online verses and Pexels backgrounds
- **Set wallpaper** — apply generated wallpapers
- **Photos / media** — select gallery images for backgrounds
- **Notifications** — related to scheduling (where applicable on your device)
- **Exact alarm / background work** — optional scheduled daily wallpaper updates via WorkManager
- **Battery optimization exemption** — optional, to improve reliability of scheduled updates

You can deny permissions; some features may not work without them.

---

## Data retention and deletion

Local app data remains until you clear app storage or uninstall the App. The App does not maintain a remote profile for you.

---

## Security

Secrets such as the Pexels API key are intended to be supplied at build time, not typed by users. Communication with third-party APIs uses HTTPS where supported.

---

## Children’s privacy

The App is not directed at collecting personal information from children. It does not offer social features or accounts.

---

## Changes to this policy

This policy may be updated when the App changes. The “Last updated” date will be revised. Continued use after changes constitutes acceptance of the updated policy.

---

## Contact

For privacy questions about DailyFaith / Zane Daily Faith, contact the developer through the Buy Me a Coffee profile or other contact method listed on your Google Play store listing.

---

## Third-party links

- [Pexels Terms](https://www.pexels.com/terms-of-service/)
- [Buy Me a Coffee](https://buymeacoffee.com/zane.daily.faith) (optional support)
