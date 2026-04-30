# Building for Android

`export_presets.cfg` ships with two presets: **Android (APK — testing)** and **Android Play Store (AAB — release)**. Both target arm64-v8a only, min SDK 24, target SDK 34, with `wake_lock` as the sole permission.

## One-time setup

1. **Install JDK 17** (Temurin or Oracle). Set `JAVA_HOME`.
2. **Install Android Studio**, run it once, accept SDK licenses. The Android SDK lands at `%LOCALAPPDATA%\Android\Sdk` on Windows.
3. In Godot: **Editor → Editor Settings → Export → Android**:
   - `Android SDK Path` → your SDK folder
   - `Debug Keystore` → leave default (Godot ships a debug keystore for testing)
4. **Generate a release keystore** (one time, keep it safe — losing it means you can't update your published app):
   ```
   keytool -genkey -v -keystore release.keystore -alias pathofevil -keyalg RSA -keysize 2048 -validity 10000
   ```
   Save it OUTSIDE the project folder (e.g., `~/keystores/path_of_evil_release.keystore`).
5. In Godot, open the **Android Play Store (AAB — release)** preset and fill in:
   - `Keystore → Release` → absolute path to the file above
   - `Keystore → Release User` → `pathofevil` (your alias)
   - `Keystore → Release Password` → your password
6. **Install the Android Build Template**: in Godot, **Project → Install Android Build Template**. This unpacks a Gradle source tree into `android/build/`. Required for AAB builds (`gradle_build/use_gradle_build=true` in the release preset).

## Build

- **Test APK** (sideload to a connected device): Project → Export → pick *Android (APK — testing)* → **Export Project** → save to `builds/path_of_evil_debug.apk`. Or run directly: with the device connected and USB debugging enabled, click *Run on Device* in the editor.
- **Release AAB** (Play Store): Project → Export → pick *Android Play Store (AAB — release)* → **Export Project** → `builds/path_of_evil_release.aab`. Upload to Play Console.

## Renderer

`project.godot` already sets `renderer/rendering_method.mobile="mobile"`. Vulkan with Mobile feature set. If you target pre-2019 Adreno 5xx / Mali-T devices and see crashes, add a fallback by changing this to `"gl_compatibility"` and rebuilding (you'll lose GPUParticles2D performance on those devices).

## Texture format

Godot 4 picks ETC2/ASTC on Android automatically. No action needed.

## Signing CI

For automated builds, drop the keystore on the build agent and pass paths via env vars in a Godot headless export command:

```
godot --headless --export-release "Android Play Store (AAB — release)" builds/path_of_evil_release.aab
```
