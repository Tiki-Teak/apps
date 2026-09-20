# Surf Check — TronByt prototype

A 64×32 live surf display prototype for **Blackies, Newport Beach, CA**.

## Prototype behavior

- **Page 1 — NOW**: Blackies, PixelSkies air-temperature colors, marine-specific water-temperature colors, current wave height, GO/MEH/SHIT color dot, and a full-screen layered wave animation. Wave height controls crest size; wave period controls the approximate duration of one complete wave event.
- **Page 2 — DETAILS**: wave height, numeric period, swell direction, wind direction/speed, sunset, and the dot with literal `GO`, `MEH`, or `SHIT` wording.
- **Page 3 — FORECAST**: reactive shark mascot, condition-driven surfer-speak phrase bank, current surf/wind, and a short building/holding/fading trend.
- Page 2 and Page 3 can be toggled independently.
- `show_full_animation = True` keeps TronByt/Pixlet from cutting off the condition-driven animation at the normal app-cycle boundary.

## Data

The app uses Open-Meteo's Weather and Marine APIs. No API key is required for this prototype.

Blackies prototype coordinates:

- Latitude: `33.608879`
- Longitude: `-117.929205`
- Time zone: `America/Los_Angeles`

Weather data: © Open-Meteo, provided under its applicable attribution/license terms.

## Future spot support

The intended full version will let a user save spots by **name + latitude + longitude**, save more than three, and mark up to **three active spots** for Page-1 rotation. The first screen for each active spot will always be allowed to finish its wave-period animation before advancing.

## Notes

The GO / MEH / SHIT indicator is intentionally a playful **surf-quality** heuristic, not an ocean-safety indicator. The prototype heuristic is tuned for Blackies and can be made spot-aware later.
