# Harkai · App Store walkthrough

Five promotional screenshots using actual Flutter widgets with fictional fixtures. iPhone exports: 1206 × 2622 RGB PNG. iPad exports: 2064 × 2752 RGB PNG. Generated navy/green background, editable HTML compositions, no changes to production application behavior.

Capture: C:/flutter/flutter/bin/flutter.bat test --dart-define=CAPTURE_STORE_ARTWORK=true test/store_artwork_capture_test.dart
Tablet capture: add --dart-define=STORE_IPAD=true
Compose: node scripts/render-appstore-artwork.mjs (uses the local design-taste browser helper).

The capture harness loads Roboto and Material Icons explicitly and specifies Roboto for buttons to avoid the test renderer's Ahem fallback. Native location and API data are isolated fixtures; map tiles are OpenStreetMap with visible attribution. No public reports are created.

Single Product Page Optimization proposal: Harkai - recorrido visual 2026-11. Its screenshots require Apple review before applying the treatment to the original product page. Google Play untouched.

The capture test is opt-in to keep regular test runs independent of local fonts, network tiles, and generated artwork.
