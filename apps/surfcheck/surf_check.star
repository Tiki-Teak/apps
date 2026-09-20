"""
Applet: Surf Check
Summary: Live surf conditions with condition-driven wave animation
Description: A 64x32 surf dashboard for Blackies in Newport Beach. Open-Meteo
  provides marine/weather data. The main scene visualizes both wave height
  and period; detail and surfer-speak summary scenes follow.
Author: Greg Worthing
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

WIDTH = 64
HEIGHT = 32
FONT = "CG-pixel-3x5-mono"
FONT_BIG = "tb-8"
FRAME_MS = 500
CACHE_TTL = 60 * 10

SPOT_NAME = "BLACKIES"
TIMEZONE = "America/Los_Angeles"

MARINE_URL = "https://marine-api.open-meteo.com/v1/marine?latitude=33.608879&longitude=-117.929205&current=wave_height,wave_period,swell_wave_direction,sea_surface_temperature&hourly=wave_height,wave_period,swell_wave_direction,sea_surface_temperature&forecast_hours=8&length_unit=imperial&timezone=America%2FLos_Angeles"
WEATHER_URL = "https://api.open-meteo.com/v1/forecast?latitude=33.608879&longitude=-117.929205&current=temperature_2m,wind_speed_10m,wind_direction_10m&hourly=temperature_2m,wind_speed_10m,wind_direction_10m&daily=sunset&forecast_hours=8&forecast_days=1&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America%2FLos_Angeles"

BLACK = "#000000"
WHITE = "#FFFFFF"
OFF_WHITE = "#EAF7FF"
OCEAN_DEEP = "#06365F"
OCEAN_MID = "#087FAE"
OCEAN_LIGHT = "#20BED4"
FOAM = "#E9FCFF"
GO = "#35E06F"
MEH = "#FFD84A"
SHIT = "#F05252"

def air_temperature_color(value):
    f = float(value)
    if f <= 20: return "#FFFFFF"
    if f <= 29: return "#E0F7FA"
    if f <= 34: return "#B3E5FC"
    if f <= 39: return "#81D4FA"
    if f <= 44: return "#29B6F6"
    if f <= 49: return "#0288D1"
    if f <= 54: return "#00ACC1"
    if f <= 59: return "#9CCC65"
    if f <= 64: return "#FFF59D"
    if f <= 69: return "#FFEE58"
    if f <= 74: return "#FFA726"
    if f <= 79: return "#FB8C00"
    if f <= 89: return "#EF5350"
    if f <= 99: return "#E53935"
    return "#B71C1C"

def water_temperature_color(value):
    f = float(value)
    if f <= 49: return "#B9F4FF"
    if f <= 54: return "#72D7FF"
    if f <= 59: return "#31B8FF"
    if f <= 63: return "#20D7D0"
    if f <= 67: return "#36E4A6"
    if f <= 71: return "#8FE36D"
    if f <= 75: return "#E7DE55"
    if f <= 79: return "#FFAC43"
    if f <= 83: return "#FF7447"
    return "#FF4B4B"

def clamp(value, low, high):
    return max(low, min(high, value))

def rounded_int(value):
    return int(float(value) + 0.5)

def safe_number(value, fallback):
    return fallback if value == None else float(value)

def get_json(url):
    response = http.get(url, ttl_seconds = CACHE_TTL)
    if response.status_code != 200:
        fail("Surf Check request failed: %d" % response.status_code)
    return response.json()

def direction_name(degrees):
    d = int(float(degrees)) % 360
    if d < 22.5 or d >= 337.5: return "N"
    if d < 67.5: return "NE"
    if d < 112.5: return "E"
    if d < 157.5: return "SE"
    if d < 202.5: return "S"
    if d < 247.5: return "SW"
    if d < 292.5: return "W"
    return "NW"

def format_sunset(value):
    if not value or len(value) < 5:
        return "--:--"
    hour = int(value[-5:-3])
    minute = value[-2:]
    if hour == 0: hour = 12
    elif hour > 12: hour -= 12
    return "%d:%s" % (hour, minute)

def wave_trend(hourly):
    values = hourly.get("wave_height", [])
    if len(values) < 2 or values[0] == None or values[-1] == None:
        return "HOLDING"
    delta = float(values[-1]) - float(values[0])
    if delta >= 0.5: return "BUILDING"
    if delta <= -0.5: return "FADING"
    return "HOLDING"

def get_state():
    marine = get_json(MARINE_URL)
    weather = get_json(WEATHER_URL)
    mc = marine.get("current", {})
    wc = weather.get("current", {})
    sunsets = weather.get("daily", {}).get("sunset", [])

    state = {
        "wave_height": safe_number(mc.get("wave_height"), 0),
        "period": safe_number(mc.get("wave_period"), 8),
        "swell_direction_degrees": safe_number(mc.get("swell_wave_direction"), 0),
        "water_temp": safe_number(mc.get("sea_surface_temperature"), 0) * 9.0 / 5.0 + 32.0,
        "air_temp": safe_number(wc.get("temperature_2m"), 0),
        "wind_speed": safe_number(wc.get("wind_speed_10m"), 0),
        "wind_direction_degrees": safe_number(wc.get("wind_direction_10m"), 0),
        "sunset": format_sunset(sunsets[0]) if sunsets else "--:--",
        "trend": wave_trend(marine.get("hourly", {})),
        "hour": time.now().in_location(TIMEZONE).hour,
    }
    state["swell_direction"] = direction_name(state["swell_direction_degrees"])
    state["wind_direction"] = direction_name(state["wind_direction_degrees"])
    state["rating"] = rate_conditions(state)
    return state

def rate_conditions(state):
    h = state["wave_height"]
    p = state["period"]
    wind = state["wind_speed"]
    deg = state["wind_direction_degrees"]
    score = 0

    if h >= 1.5 and h <= 6.0: score += 2
    elif h >= 1.0 and h <= 8.0: score += 1
    else: score -= 1

    if p >= 12: score += 2
    elif p >= 9: score += 1
    elif p < 7: score -= 1

    if wind <= 5: score += 2
    elif wind <= 10: score += 1
    elif wind >= 18: score -= 1

    # Rough Blackies wind preference. This is surf-vibe scoring, not a safety rating.
    if wind >= 4 and deg >= 45 and deg <= 135: score += 1
    elif wind >= 8 and deg >= 180 and deg <= 300: score -= 1

    if score >= 5: return "GO"
    if score >= 2: return "MEH"
    return "SHIT"

def rating_color(rating):
    if rating == "GO": return GO
    if rating == "MEH": return MEH
    return SHIT

def rect(x, y, width, height, color):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(width = width, height = height, color = color),
    )

def text_at(x, y, content, color = WHITE, font = FONT):
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Text(content = content, color = color, font = font),
    )

def sun_icon(x, y, color):
    return render.Stack(children = [
        rect(x + 2, y + 2, 3, 3, color),
        rect(x + 3, y, 1, 1, color),
        rect(x + 3, y + 6, 1, 1, color),
        rect(x, y + 3, 1, 1, color),
        rect(x + 6, y + 3, 1, 1, color),
        rect(x + 1, y + 1, 1, 1, color),
        rect(x + 5, y + 1, 1, 1, color),
        rect(x + 1, y + 5, 1, 1, color),
        rect(x + 5, y + 5, 1, 1, color),
    ])

def drop_icon(x, y, color):
    return render.Stack(children = [
        rect(x + 3, y, 1, 1, color),
        rect(x + 2, y + 1, 3, 1, color),
        rect(x + 1, y + 2, 5, 2, color),
        rect(x + 2, y + 4, 3, 1, color),
    ])

def wave_amplitude(height_ft):
    if height_ft < 1.5: return 3
    if height_ft < 3: return 6
    if height_ft < 5: return 10
    if height_ft < 7: return 13
    if height_ft < 10: return 16
    return 19

def wave_background(state, frame_index, frame_count):
    amp = wave_amplitude(state["wave_height"])
    travel = WIDTH + amp * 2 + 8
    center = -amp - 4 + int(travel * frame_index / max(1, frame_count - 1))
    pieces = [rect(0, 30, WIDTH, 2, OCEAN_DEEP)]

    for x in range(WIDTH):
        dist = abs(x - center)
        lift = max(0, amp - int(dist * 0.75))
        # Long-period swell gets a smoother face; short period gets subtle chop.
        chop = 0
        if state["period"] < 9 and ((x + frame_index) % 9 == 0):
            chop = 1
        top = clamp(29 - lift - chop, 7, 30)
        color = OCEAN_LIGHT if lift >= max(3, amp // 2) else OCEAN_MID
        pieces.append(rect(x, top, 1, HEIGHT - top, color))

        if lift >= max(3, amp - 3) and ((x + frame_index) % 2 == 0):
            pieces.append(rect(x, max(6, top - 1), 1, 1, FOAM))
        elif lift >= max(2, amp // 2) and ((x + frame_index) % 4 == 0):
            pieces.append(rect(x, top, 1, 1, FOAM))

    return render.Stack(children = pieces)

def page_one(state, frame_index, frame_count):
    air_color = air_temperature_color(state["air_temp"])
    water_color = water_temperature_color(state["water_temp"])
    return render.Stack(children = [
        rect(0, 0, WIDTH, HEIGHT, BLACK),
        wave_background(state, frame_index, frame_count),
        text_at(1, 0, SPOT_NAME, OFF_WHITE),
        rect(59, 1, 3, 3, rating_color(state["rating"])),
        sun_icon(1, 7, air_color),
        text_at(10, 7, "%d°" % rounded_int(state["air_temp"]), air_color),
        drop_icon(37, 8, water_color),
        text_at(46, 7, "%d°" % rounded_int(state["water_temp"]), water_color),
        text_at(22, 17, "%.1f'" % state["wave_height"], WHITE, FONT_BIG),
    ])

def page_two(state):
    return render.Stack(children = [
        rect(0, 0, WIDTH, HEIGHT, BLACK),
        text_at(1, 0, SPOT_NAME, OFF_WHITE),
        rect(47, 1, 3, 3, rating_color(state["rating"])),
        text_at(52, 0, state["rating"], rating_color(state["rating"])),
        text_at(1, 7, "WAVE %.1f'" % state["wave_height"], OCEAN_LIGHT),
        text_at(1, 13, "PER %dS" % rounded_int(state["period"]), FOAM),
        text_at(34, 13, "SW %s" % state["swell_direction"], FOAM),
        text_at(1, 19, "WIND %s %d" % (state["wind_direction"], rounded_int(state["wind_speed"])), OFF_WHITE),
        text_at(1, 25, "SUNSET %s" % state["sunset"], "#FFB44A"),
    ])

GO_PHRASES = ["LOOKIN' FUN", "GET ON IT", "PRETTY CLEAN", "SOME JUICE", "WORTH A PADDLE", "EARLY LOOKS GOOD"]
MEH_PHRASES = ["MIXED BAG", "COULD BE FUN", "KINDA BUMPY", "WORTH A LOOK", "PICK YOUR WINDOW", "NOT BAD, NOT GREAT"]
SHIT_PHRASES = ["MAYBE COFFEE", "PRETTY MESSY", "NOT MUCH DOING", "BLOWN OUT", "LONGBOARD OR NAP", "TRY AGAIN LATER"]

def forecast_phrase(state):
    phrases = GO_PHRASES if state["rating"] == "GO" else (MEH_PHRASES if state["rating"] == "MEH" else SHIT_PHRASES)
    return phrases[state["hour"] % len(phrases)]

SHARK_GO_A = [
    "0000033000000",
    "0003333330000",
    "0033333333000",
    "0333111333300",
    "3333333333330",
    "0333333333300",
    "0033444333000",
    "0004000400000",
]
SHARK_GO_B = [
    "0000330000000",
    "0033333300000",
    "0333333330000",
    "3331133333000",
    "3333333333330",
    "0333333333300",
    "0003444330000",
    "0000400400000",
]
SHARK_MEH_A = [
    "0000033000000",
    "0003333330000",
    "0033333333000",
    "0333331333300",
    "3333313333330",
    "0333333333300",
    "0033444333000",
    "0004000400000",
]
SHARK_MEH_B = [
    "0000330000000",
    "0033333300000",
    "0333333330000",
    "3333331333000",
    "3333133333330",
    "0333333333300",
    "0003444330000",
    "0000400400000",
]
SHARK_SHIT_A = [
    "5000033000005",
    "0003333330500",
    "0033333333000",
    "0333313333300",
    "3333331333330",
    "0333333333300",
    "0033444333000",
    "0504000400050",
]
SHARK_SHIT_B = [
    "0500330000050",
    "0033333300000",
    "0333333330500",
    "3331333333000",
    "3333313333330",
    "0333333333300",
    "0003444330000",
    "5000400400005",
]

def shark_sprite(pattern, x, y):
    colors = {
        "1": BLACK,
        "3": "#79A9C4",
        "4": "#EAF7FF",
        "5": OCEAN_LIGHT,
    }
    pixels = []
    for row in range(len(pattern)):
        line = pattern[row]
        for col in range(len(line)):
            key = line[col:col + 1]
            if key in colors:
                pixels.append(rect(x + col, y + row, 1, 1, colors[key]))
    return render.Stack(children = pixels)

def shark_for(state, alternate):
    if state["rating"] == "GO":
        pattern = SHARK_GO_B if alternate else SHARK_GO_A
    elif state["rating"] == "MEH":
        pattern = SHARK_MEH_B if alternate else SHARK_MEH_A
    else:
        pattern = SHARK_SHIT_B if alternate else SHARK_SHIT_A
    return shark_sprite(pattern, 49, 22)

def page_three(state, alternate):
    return render.Stack(children = [
        rect(0, 0, WIDTH, HEIGHT, BLACK),
        text_at(1, 0, forecast_phrase(state), rating_color(state["rating"])),
        text_at(1, 7, "%.1f' @ %dS" % (state["wave_height"], rounded_int(state["period"])), FOAM),
        text_at(1, 13, "%s SWELL" % state["swell_direction"], OCEAN_LIGHT),
        text_at(1, 19, "%s %d MPH" % (state["wind_direction"], rounded_int(state["wind_speed"])), OFF_WHITE),
        text_at(1, 25, state["trend"], MEH if state["trend"] == "HOLDING" else OCEAN_LIGHT),
        shark_for(state, alternate),
    ])

def main(config):
    state = get_state()

    # One complete Page-1 wave event roughly follows the current wave period.
    # TronByt's show_full_animation flag prevents the device cycle timer from
    # cutting the animation off before the app reaches the later pages.
    period_seconds = clamp(rounded_int(state["period"]), 6, 18)
    wave_frames = period_seconds * int(1000 / FRAME_MS)
    frames = [page_one(state, i, wave_frames) for i in range(wave_frames)]

    if config.bool("show_details", True):
        frames += [page_two(state) for _ in range(10)]

    if config.bool("show_summary", True):
        frames += [page_three(state, (i // 2) % 2 == 1) for i in range(12)]

    return render.Root(
        delay = FRAME_MS,
        show_full_animation = True,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_details",
                name = "Details page",
                desc = "Wave period, swell, wind, sunset and GO / MEH / SHIT wording.",
                icon = "list",
                default = True,
            ),
            schema.Toggle(
                id = "show_summary",
                name = "Surfer forecast",
                desc = "Shark mascot and surfer-speak forecast summary.",
                icon = "messageCircle",
                default = True,
            ),
        ],
    )
