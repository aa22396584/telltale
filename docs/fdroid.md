# F-Droid maintainer notes

F-Droid builds Telltale from the **Codeberg** mirror. Play assets live in
`store/`; F-Droid listing graphics and copy are synced into
`fastlane/metadata/android/` (see `tool/fdroid/sync_fastlane_from_store.sh`).

## Exact build command (F-Droid recipe)

```bash
flutter build apk --release --flavor field -PallowUnsignedRelease=true
```

- **Flavor:** `field` only (`applicationId` `com.cbstudio.telltale`). Do not
  build `rig` or `wear`.
- **Unsigned escape hatch:** required when `android/key.properties` is absent
  (F-Droid has no maintainer keystore). The Gradle gate is in
  `android/app/build.gradle.kts`.
- **Expected fat APK:** `build/app/outputs/flutter-apk/app-field-release.apk`
- **Flutter pin:** `3.47.0` (CI `FLUTTER_VERSION` / `.fvmrc`)

## Signing lineages (three keys)

| Channel | Signer | Updates |
| --- | --- | --- |
| F-Droid | F-Droid signing key | Only other F-Droid builds |
| Community release | Community key (GitHub Actions) | Only other community builds |
| Google Play | Play upload / App Signing | Only Play updates |

Do **not** upload a community or Play APK into F-Droid.

## Sync Fastlane from Play store assets

After editing `store/`:

```bash
tool/fdroid/sync_fastlane_from_store.sh
```

Then commit the Fastlane tree with the store change.
