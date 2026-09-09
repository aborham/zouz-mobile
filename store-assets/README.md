# Zouz store assets

## Generate screenshots

Place real, current app captures in `screenshots/raw`, update `screenshots/manifest.json`, then run:

```bash
python3 tool/generate_store_screenshots.py
```

Outputs:

- `screenshots/generated/app-store-iphone-6.9`: 1290 × 2796 JPG
- `screenshots/generated/google-play-phone`: 1080 × 1920 JPG

The iOS target supports iPad. Capture the same screens on a real 13-inch iPad simulator, update the manifest to point at those captures, then run with `--tablet`. Do not stretch iPhone captures and submit them as iPad UI.

## Google Play graphics

- Developer icon: `google-play/zouz-developer-icon-512.png`
- Developer header: `google-play/zouz-developer-header-4096x2304.jpg`
- App feature graphic: `google-play/zouz-feature-graphic-1024x500.jpg`

All published screenshots must use real app UI, avoid personal information, and match the version submitted for review.
