# Foodie launch experience

Android shows the existing app icon on a dark green native launch
background. Android 12+ uses platform splash attributes, including a 200x80 dp branding image (600x240 pixels in drawable-xxhdpi) with Foodie and the exact developer credit. Older Android versions use the same image in a bottom-aligned launch layer. No splash generator
or additional package is needed. The iOS native launch storyboard is unchanged.

`main.dart` renders `FoodieStartup` immediately. Session, theme, and optional
Stripe setup run concurrently behind `FoodieSplash`. The splash stays visible
for at least 1.1 seconds, overlapping initialization, then opens the existing
app router. Startup errors offer Retry; session validation still uses the
existing session error flow. This splash appears once per process launch, not
on every resume or route change.

The existing `assets/branding/app_logo.png` is reused with a 256-pixel decode
target. Food decorations are small CustomPainter vectors: only a small bundled flag and native branding bitmap,
network fonts, image downloads, or dependencies. Branding enters over 700ms;
food floats gently on a 3.2-second reversing cycle. Reduced-motion settings stop
the motion and show branding immediately. The splash always uses branded dark green, independent of the saved app theme. The normal app still honors its theme preference.

Tests cover startup waiting/retry, phone/landscape layouts, large text, and
reduced motion. To render optional previews while running
`flutter test test/foodie_splash_test.dart`, set FOODIE_SPLASH_PREVIEW to a local
output directory and optionally FOODIE_PREVIEW_FONT to a local TTF font path.
Neither environment variable is needed by the app.

Rebuild/reinstall to see native launch changes. Use the existing
`scripts/build-sandbox.ps1 -Run` workflow to retain development API/Stripe
configuration. A plain debug build verifies compilation but does not include
the sandbox script's payment configuration. No manual asset setup is needed.

## Final branding

The custom splash displays the Sri Lankan flag below the logo and above Foodie.
The exact credit is displayed below the loading text inside SafeArea:

Developed by Soft. Dev | G 04 for Young Protégé 2026.

Flag asset: assets/branding/sri_lanka_flag.png (80x40), downloaded once from
https://flagcdn.com/w80/lk.png. Source information: https://flagcdn.com/ (based on
Wikimedia Commons flags). The existing assets/branding/ registration bundles it;
there is no runtime network request or emoji dependency.

Android reference: https://developer.android.com/develop/ui/views/launch/splash-screen
The platform positions the Android 12+ branding image; no extra native Activity,
custom text layout, or launch delay was added.
