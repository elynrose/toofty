# todoos

Flutter app for kids' brushing routines — rewards, monsters, and parent-managed profiles backed by Firebase Auth and Firestore.

## Play Store release

### 1. Generate upload keystore (once)

```bash
chmod +x scripts/*.sh
./scripts/generate_upload_keystore.sh
```

Back up `android/upload-keystore.jks` and the passwords printed by the script. Both files are gitignored.

### 2. Register release SHA with Firebase

Google Sign-In on release builds requires your upload certificate fingerprints in Firebase:

```bash
./scripts/register_release_sha_firebase.sh
```

Add the SHA-1 and SHA-256 values in [Firebase Console](https://console.firebase.google.com/project/todoos-briktap/settings/general) under the Android app (`com.todoos.todoos`), then re-download `google-services.json` into `android/app/`.

After your **first** Play Store upload, also add the **Play App Signing** certificate SHA from Play Console → Release → Setup → App signing.

### 3. Build the App Bundle

```bash
./scripts/build_playstore_aab.sh
```

Upload `build/app/outputs/bundle/release/app-release.aab` to [Google Play Console](https://play.google.com/console).

Also upload the **deobfuscation mapping file** with the same release (removes the Play Console warning):

```
build/app/outputs/mapping/release/mapping.txt
```

Play Console → **Release** → **App bundle explorer** → select your version → **Downloads** → **Upload mapping file**

Or run the full interactive flow:

```bash
./scripts/playstore_prepare.sh
```

### 4. Play Console checklist

| Item | Notes |
|------|--------|
| App bundle | `app-release.aab` from step 3 |
| Version | Set in `pubspec.yaml` (`version: 1.0.0+1` → name + build number) |
| Store listing | Title **Toofty**, descriptions, screenshots, 1024×500 feature graphic |
| Privacy policy | **Required** — app collects email/account data via Firebase |
| Account deletion | **Required** — use `https://todoos-briktap.web.app/delete-account.html` |
| Data safety | Declare authentication, account info, app activity |
| Content rating | Complete IARC questionnaire |
| Target audience | If aimed at children, complete Families / COPPA declarations |
| Play App Signing | Use Google-managed signing (recommended); enroll upload key on first release |

### Version bumps

Before each release, increment in `pubspec.yaml`:

```yaml
version: 1.0.1+2   # 1.0.1 = versionName, 2 = versionCode (must increase every upload)
```

## Development

```bash
flutter pub get
flutter run
```

Firebase project: `todoos-briktap`. See `scripts/setup_firebase.sh` for initial Firebase setup.

## iOS build

Prerequisites: Xcode (from App Store), CocoaPods (`brew install cocoapods`).

```bash
chmod +x scripts/build_ios.sh
./scripts/build_ios.sh              # simulator debug build
./scripts/build_ios.sh --release      # device release (sign in Xcode)
./scripts/build_ios.sh --ipa          # App Store .ipa
```

Open **`ios/Runner.xcworkspace`** (not `.xcodeproj`) in Xcode for signing and device runs.

- **iOS Bundle ID:** `com.briktap.toofty`
- **Android package:** `com.todoos.todoos`
- **Display name:** Toofty
- **Signing:** Select your Apple Developer Team under Signing & Capabilities
- **Google Sign-In:** Add your iOS URL scheme from `GoogleService-Info.plist` (already in `Info.plist`)

Run on simulator after a debug build:

```bash
open -a Simulator && flutter run -d ios
```

## App Store release

### Prerequisites

1. **Apple Developer Program** ($99/year) — [developer.apple.com/programs](https://developer.apple.com/programs)
2. Register bundle ID **`com.briktap.toofty`** in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
3. Enable **Sign in with Apple** on that App ID (required for App Store Guideline 4.8 when Google Sign-In is offered)
4. **Distribution certificate** — Xcode creates this on first Archive (Signing & Capabilities → your Team)
5. In [Firebase Console](https://console.firebase.google.com/project/todoos-briktap/authentication/providers) → **Authentication** → **Sign-in method** → enable **Apple**

### Build & upload

```bash
chmod +x scripts/appstore_prepare.sh
./scripts/appstore_prepare.sh
```

Or manually:

```bash
./scripts/build_ios.sh --ipa
```

Upload **`build/ios/ipa/Toofty.ipa`** via [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) or Xcode → Product → Archive → Distribute App.

### App Store Connect ([appstoreconnect.apple.com](https://appstoreconnect.apple.com))

| Field | Value |
|-------|--------|
| App name | **Toofty** |
| Bundle ID | `com.briktap.toofty` |
| Privacy Policy URL | `https://todoos-briktap.web.app/privacy.html` |
| Account deletion URL | `https://todoos-briktap.web.app/delete-account.html` |
| Category | Health & Fitness or Lifestyle |
| Version | 1.0.0 (build 3) |

**Screenshots required:** iPhone 6.7" and iPad 12.9" (app supports iPad).

**App Privacy:** Declare email, user ID, and app activity; linked to identity; used for app functionality.

**Age rating:** Complete the questionnaire. App is parent-managed; not directed at children under 13 to sign up directly.

### Version bumps

Increment in `pubspec.yaml` before each submission (`1.0.1+2` = version 1.0.1, build 2).
