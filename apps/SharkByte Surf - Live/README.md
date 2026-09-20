# SharkByte Surf - Live

A 64×32 TronByt/Pixlet surf-conditions app.

## What it does

**Page 1 — NOW**
- Spot name
- Air temperature using the PixelSkies temperature-color scale
- Sea-surface temperature using a surf-specific color scale
- Current modeled wave height
- GO / MEH / SHIT color dot
- Animated ocean/wave behind the data
- Wave height controls visual wave size
- Wave period controls the duration of a complete wave pass
- `show_full_animation = True` prevents the normal app dwell time from cutting the animation short

**Page 2 — DETAILS**
- Wave height
- Numeric wave period
- Swell direction
- Wind direction and speed in knots
- Sunset
- Dot plus the literal GO / MEH / SHIT wording

**Page 3 — SHARK FORECAST**
- Condition-reactive shark mascot
- Multiple shark looks/poses within each condition category
- Surfer-speak headline chosen from a phrase bank
- Wave / period / swell / wind
- Building / holding / fading trend

## Surf spots

Six spots can be saved in settings. Each spot uses only:
- a display name
- coordinates entered as `latitude,longitude`

Example Blackies coordinates:

`33.608879,-117.929205`

Choose up to three Active Spots. Page 1 plays one full period-driven wave animation for each active spot before moving on. **Active Spot 1 is the primary spot**, so Pages 2 and 3 use that spot.

## Condition dot

The condition dot is a playful surf-quality shorthand, not a safety rating:
- Green: **GO**
- Yellow: **MEH**
- Red: **SHIT**

The settings include a preferred minimum and maximum surf height so the quality heuristic can better match the surfer using the display. Period and wind speed also contribute.

## Data

Weather and marine data come from Open-Meteo. The app uses:
- Open-Meteo Weather API for air temperature, wind, and sunset
- Open-Meteo Marine API for modeled wave height, period, swell direction, and sea-surface temperature

No API key is required for normal prototype/personal use. Open-Meteo marine wave height is model-based significant wave height; it should not be treated as a measured breaking-wave face height at the beach.

## Install on TronByt Server

This build is inside Greg's `Tiki-Teak/apps` fork of the TronByt system-app catalog.

**Use it as the System Apps Repository, not the Custom Apps Repository.** TronByt treats every folder in a custom-app repo as a personal app, so pointing the full catalog fork at Custom Apps would duplicate the entire catalog.

For Greg's server:

1. Open **Settings → Content and Firmware**.
2. Under **System Apps Repository**, confirm the repository is `https://github.com/Tiki-Teak/apps.git`.
   - If it already is, just press **Refresh**.
   - If it still points to the official TronByt apps repo, replace it with the Tiki-Teak fork and save. The fork contains the normal TronByt catalog plus SharkByte.
3. Open the display/device and choose **Add App**.
4. Search System Apps for **SharkByte Surf - Live**.
5. Add it. For the first hardware test, leave the default Blackies spot active by itself.
6. Save the app and let the complete animation run. SharkByte requests `show_full_animation = True`, so its period-driven wave cycle should finish even when the normal device app-cycle time is shorter.

After future SharkByte updates, use **Settings → Content and Firmware → System Apps Repository → Refresh** before checking the new build.

