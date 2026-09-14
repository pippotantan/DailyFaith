# Google Play Release — DailyFaith

Application ID: **`com.zanedailyfaith.biblewallpaper`**

## 1. Upload keystore (one-time, local)

Create a keystore outside the repository (example path):

```bash
keytool -genkey -v \
  -keystore "$HOME/.android/zane-daily-faith-upload.jks" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Use your own secure passwords when prompted. Do not commit the keystore or passwords.

Copy the signing template:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` with your local paths and passwords. This file is gitignored.

## 2. Build secrets (Pexels + privacy policy URL)

Copy:

```bash
cp dart_defines.json.example dart_defines.json
```

Edit `dart_defines.json` with:

- **`PEXELS_API_KEY`** — from [Pexels API](https://www.pexels.com/api/). Rotate any key that was previously committed to source control.
- **`PRIVACY_POLICY_URL`** — public HTTPS URL where you host the contents of [`privacy-policy.md`](privacy-policy.md) (GitHub Pages, your website, etc.).

`dart_defines.json` is gitignored.

## 3. Build the App Bundle

```bash
flutter pub get
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload this AAB to Google Play Console. Enroll in **Play App Signing** so Google manages the app signing key; your local keystore is the **upload key**.

## 4. Debug / local release runs

- **Debug** builds do not require `key.properties`.
- **Release** builds require `android/key.properties` (upload keystore).
- Pexels backgrounds require `PEXELS_API_KEY` in `dart_defines.json` (or pass `--dart-define=PEXELS_API_KEY=...`).
- Without a Pexels key, local gallery and offline verses still work.

## 5. Play Console checklist

- Store listing assets and descriptions
- Content rating questionnaire
- Data safety form (align with `privacy-policy.md`)
- Privacy policy URL (same as `PRIVACY_POLICY_URL`)
- Permission declarations (photos, alarms, notifications as applicable)
