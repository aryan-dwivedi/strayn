# strayn

iOS wellness app (SwiftUI) — recovery, strain, sleep, and healthspan tracking.

## Requirements

- Xcode 16+
- iOS 17+ (simulator or device)

## Build locally

```bash
xcodebuild build \
  -project strayn.xcodeproj \
  -scheme strayn \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Open `strayn.xcodeproj` in Xcode to run on a simulator.

## CI

GitHub Actions builds the app for the iOS Simulator on every push and pull request to `main` (see `.github/workflows/ci.yml`).
