# Surf Check — Blackies prototype

A **64×32 TronByt surf app prototype** for Blackies in Newport Beach, California.

## What is in the prototype

- **Page 1 — Quick Conditions**
  - Blackies
  - air temperature using PixelSkies-style temperature colors
  - water temperature using a separate marine color scale
  - current wave height
  - GO / MEH / SHIT color dot
  - animated ocean/wave background
  - wave size changes with reported wave height
  - the full Page-1 animation lasts approximately one reported wave period

- **Page 2 — Details**
  - wave height
  - numeric period
  - swell direction
  - wind direction and speed
  - sunset
  - condition dot plus GO / MEH / SHIT wording

- **Page 3 — Surfer Forecast**
  - short surfer-speak phrase bank
  - surf / swell / wind / trend
  - small reactive shark mascot with alternating frames

## Full-animation behavior

This app sets `show_full_animation = True`.

That is a TronByt/Pixlet feature requesting that the complete animation play even when it is longer than the device's normal app cycle time. That matters here because Page 1 uses the reported wave period as part of the presentation.

## Data

Prototype coordinates:

- Blackies
- latitude: `33.608879`
- longitude: `-117.929205`
- timezone: `America/Los_Angeles`

Data comes from Open-Meteo Weather and Marine APIs.

The GO / MEH / SHIT indicator is a playful **surf-quality** heuristic, not a safety indicator.

## Next step after the first display test

This is intentionally Blackies-only for the first physical-display visual test. Once the layout and animation look right, the next version can add the agreed location workflow:

**Add Spot → Name + Latitude + Longitude → Save**

with many saved spots and up to three active spots.
