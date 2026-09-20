"""
Applet: SharkByte Surf - Live
Summary: Live surf conditions with wave-period animation
Description: A 64x32 live surf dashboard with animated waves, surf details,
  and a condition-reactive shark forecast mascot. Data by Open-Meteo.
Author: Greg Worthing
"""

load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

WIDTH = 64
HEIGHT = 32
FONT = "CG-pixel-3x5-mono"
FONT_BIG = "tb-8"
FRAME_MS = 250
WAVE_PHASES = 12
CACHE_TTL = 60 * 10

BLACK = "#000000"
WHITE = "#FFFFFF"
OFF_WHITE = "#EAF7FF"
OCEAN_DEEP = "#042B55"
OCEAN_MID = "#086A97"
OCEAN_LIGHT = "#14B9D0"
OCEAN_GLOW = "#39D9E8"
FOAM = "#E8FDFF"
GO = "#35E06F"
MEH = "#FFD84A"
SHIT = "#F05252"
SUNSET = "#FFB44A"
SHARK = "#8CB8C8"
SHARK_LIGHT = "#C8E8EF"
SEAWEED = "#69B34C"

SLOT_OPTIONS = [
    schema.Option(display = "Saved Spot 1", value = "1"),
    schema.Option(display = "Saved Spot 2", value = "2"),
    schema.Option(display = "Saved Spot 3", value = "3"),
    schema.Option(display = "Saved Spot 4", value = "4"),
    schema.Option(display = "Saved Spot 5", value = "5"),
    schema.Option(display = "Saved Spot 6", value = "6"),
]

SECONDARY_SLOT_OPTIONS = [
    schema.Option(display = "Off", value = "0"),
] + SLOT_OPTIONS

MIN_OPTIONS = [
    schema.Option(display = "1 ft", value = "1"),
    schema.Option(display = "1.5 ft", value = "1.5"),
    schema.Option(display = "2 ft", value = "2"),
    schema.Option(display = "2.5 ft", value = "2.5"),
    schema.Option(display = "3 ft", value = "3"),
    schema.Option(display = "4 ft", value = "4"),
]

MAX_OPTIONS = [
    schema.Option(display = "4 ft", value = "4"),
    schema.Option(display = "5 ft", value = "5"),
    schema.Option(display = "6 ft", value = "6"),
    schema.Option(display = "8 ft", value = "8"),
    schema.Option(display = "10 ft", value = "10"),
    schema.Option(display = "12 ft", value = "12"),
]

def air_temperature_color(value):
    f = float(value)
    if f <= 20:
        return "#FFFFFF"
    if f <= 29:
        return "#E0F7FA"
    if f <= 34:
        return "#B3E5FC"
    if f <= 39:
        return "#81D4FA"
    if f <= 44:
        return "#29B6F6"
    if f <= 49:
        return "#0288D1"
    if f <= 54:
        return "#00ACC1"
    if f <= 59:
        return "#9CCC65"
    if f <= 64:
        return "#FFF59D"
    if f <= 69:
        return "#FFEE58"
    if f <= 74:
        return "#FFA726"
    if f <= 79:
        return "#FB8C00"
    if f <= 89:
        return "#EF5350"
    if f <= 99:
        return "#E53935"
    return "#B71C1C"

def water_temperature_color(value):
    f = float(value)
    if f <= 49:
        return "#B9F4FF"
    if f <= 54:
        return "#72D7FF"
    if f <= 59:
        return "#31B8FF"
    if f <= 63:
        return "#20D7D0"
    if f <= 67:
        return "#36E4A6"
    if f <= 71:
        return "#8FE36D"
    if f <= 75:
        return "#E7DE55"
    if f <= 79:
        return "#FFAC43"
    if f <= 83:
        return "#FF7447"
    return "#FF4B4B"

def clamp(value, low, high):
    return max(low, min(high, value))

def rounded_int(value):
    return int(float(value) + 0.5)

def one_decimal(value):
    tenths = int(float(value) * 10.0 + 0.5)
    return "%d.%d" % (tenths // 10, tenths % 10)

def direction_name(degrees):
    d = int(float(degrees)) % 360
    if d < 22.5 or d >= 337.5:
        return "N"
    if d < 67.5:
        return "NE"
    if d < 112.5:
        return "E"
    if d < 157.5:
        return "SE"
    if d < 202.5:
        return "S"
    if d < 247.5:
        return "SW"
    if d < 292.5:
        return "W"
    return "NW"

def format_sunset(value):
    if not value or len(value) < 5:
        return "--:--"
    hour = int(value[-5:-3])
    minute = value[-2:]
    if hour == 0:
        hour = 12
    elif hour > 12:
        hour = hour - 12
    return "%d:%s" % (hour, minute)

def hour_from_iso(value):
    if value and len(value) >= 13:
        return int(value[11:13])
    return 8

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

def outlined_text_at(x, y, content, color = WHITE, font = FONT):
    return render.Stack(children = [
        text_at(x - 1, y, content, BLACK, font),
        text_at(x + 1, y, content, BLACK, font),
        text_at(x, y - 1, content, BLACK, font),
        text_at(x, y + 1, content, BLACK, font),
        text_at(x, y, content, color, font),
    ])

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

def slot_name(config, slot):
    if slot == 1:
        return config.str("spot1_name", "BLACKIES")
    return config.str("spot%d_name" % slot, "")

def slot_coords(config, slot):
    if slot == 1:
        return config.str("spot1_coords", "33.608879,-117.929205")
    return config.str("spot%d_coords" % slot, "")

def spot_from_slot(config, slot):
    name = slot_name(config, slot)
    coords = slot_coords(config, slot).replace(" ", "")
    parts = coords.split(",")
    if not name or len(parts) != 2 or not parts[0] or not parts[1]:
        return None
    return {
        "slot": slot,
        "name": name,
        "lat": parts[0],
        "lon": parts[1],
    }

def active_spots(config):
    choices = [
        int(config.str("active1", "1")),
        int(config.str("active2", "0")),
        int(config.str("active3", "0")),
    ]
    spots = []
    seen = {}
    for slot in choices:
        if slot > 0 and not seen.get(str(slot), False):
            spot = spot_from_slot(config, slot)
            if spot:
                spots.append(spot)
                seen[str(slot)] = True
    return spots

def marine_url(spot):
    return "https://marine-api.open-meteo.com/v1/marine?latitude=%s&longitude=%s&current=wave_height,wave_period,swell_wave_direction,sea_surface_temperature&hourly=wave_height,wave_period,swell_wave_direction&forecast_hours=8&length_unit=imperial&timezone=auto" % (spot["lat"], spot["lon"])

def weather_url(spot):
    return "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,wind_speed_10m,wind_direction_10m&hourly=wind_speed_10m&daily=sunset&forecast_hours=8&forecast_days=1&temperature_unit=fahrenheit&wind_speed_unit=kn&timezone=auto" % (spot["lat"], spot["lon"])

def fetch_json(url):
    response = http.get(url, ttl_seconds = CACHE_TTL)
    if response.status_code != 200:
        return None
    return response.json()

def wave_trend(hourly):
    heights = hourly.get("wave_height", [])
    if len(heights) < 2 or heights[0] == None or heights[-1] == None:
        return "HOLDING"
    delta = float(heights[-1]) - float(heights[0])
    if delta >= 0.5:
        return "BUILDING"
    if delta <= -0.5:
        return "FADING"
    return "HOLDING"

def rate_conditions(state, preferred_min, preferred_max):
    h = state["wave_height"]
    p = state["period"]
    wind = state["wind_speed"]
    score = 0

    if h >= preferred_min and h <= preferred_max:
        score += 2
    elif h >= preferred_min * 0.65 and h <= preferred_max * 1.35:
        score += 1
    else:
        score -= 1

    if p >= 13:
        score += 2
    elif p >= 9:
        score += 1
    elif p < 7:
        score -= 1

    if wind <= 5:
        score += 2
    elif wind <= 10:
        score += 1
    elif wind >= 18:
        score -= 1

    if score >= 5:
        return "GO"
    if score >= 2:
        return "MEH"
    return "SHIT"

def get_state(spot, preferred_min, preferred_max):
    marine = fetch_json(marine_url(spot))
    weather = fetch_json(weather_url(spot))
    if not marine or not weather:
        return None

    mc = marine.get("current", {})
    wc = weather.get("current", {})
    if mc.get("wave_height") == None or mc.get("wave_period") == None:
        return None

    water_c = mc.get("sea_surface_temperature")
    water_f = float(water_c) * 9.0 / 5.0 + 32.0 if water_c != None else 0

    daily = weather.get("daily", {})
    sunsets = daily.get("sunset", [])
    state = {
        "name": spot["name"],
        "wave_height": float(mc.get("wave_height", 0)),
        "period": float(mc.get("wave_period", 8)),
        "swell_degrees": float(mc.get("swell_wave_direction", 0)),
        "water_temp": water_f,
        "air_temp": float(wc.get("temperature_2m", 0)),
        "wind_speed": float(wc.get("wind_speed_10m", 0)),
        "wind_degrees": float(wc.get("wind_direction_10m", 0)),
        "sunset": format_sunset(sunsets[0]) if sunsets else "--:--",
        "trend": wave_trend(marine.get("hourly", {})),
        "hour": hour_from_iso(wc.get("time", "")),
    }
    state["swell_direction"] = direction_name(state["swell_degrees"])
    state["wind_direction"] = direction_name(state["wind_degrees"])
    state["rating"] = rate_conditions(state, preferred_min, preferred_max)
    return state

def rating_color(rating):
    if rating == "GO":
        return GO
    if rating == "MEH":
        return MEH
    return SHIT

def wave_amplitude(height_ft):
    if height_ft < 1.5:
        return 3
    if height_ft < 3:
        return 6
    if height_ft < 5:
        return 10
    if height_ft < 7:
        return 13
    if height_ft < 10:
        return 16
    return 19

def wave_span(height_ft):
    if height_ft < 2:
        return 10
    if height_ft < 4:
        return 15
    if height_ft < 7:
        return 20
    return 24

def wave_frame(state, phase):
    amp = wave_amplitude(state["wave_height"])
    span = wave_span(state["wave_height"])
    progress = float(phase) / float(WAVE_PHASES - 1)
    center = -span + int((WIDTH + span * 2) * progress)
    base = 27
    parts = [
        rect(0, 27, WIDTH, 5, OCEAN_DEEP),
        rect(0, 29, WIDTH, 3, OCEAN_MID),
    ]

    for x in range(WIDTH):
        d = x - center
        ad = abs(d)
        lift = 0
        if ad < span:
            ratio = 1.0 - float(ad) / float(span)
            lift = int(float(amp) * ratio * ratio)

            # Give the front face a little extra pitch so it reads as a breaker.
            if d > 0 and d < max(2, span // 3):
                lift += int(float(amp) * 0.12 * (1.0 - float(d) / float(max(2, span // 3))))

        ripple = int((math.sin(float(x + phase * 4) * 0.42) + 1.0) * 0.5)
        top = clamp(base - lift - ripple, 6, 29)

        if top < 29:
            color = OCEAN_LIGHT if lift > amp // 2 else OCEAN_MID
            parts.append(rect(x, top, 1, HEIGHT - top, color))

        if lift >= max(2, int(float(amp) * 0.55)):
            parts.append(rect(x, max(5, top - 1), 1, 1, FOAM))

    # Curl / lip near the crest. Larger surf gets a more obvious overhang.
    lip = max(1, amp // 4)
    crest_y = clamp(base - amp, 5, 26)
    for i in range(lip):
        px = center + 1 + i
        py = crest_y + (i // 2)
        if px >= 0 and px < WIDTH:
            parts.append(rect(px, py, 1, 1, FOAM))
            if amp >= 10 and i < lip - 1 and py + 1 < HEIGHT:
                parts.append(rect(px, py + 1, 1, 1, OCEAN_GLOW))

    return render.Stack(children = parts)

def page_one(state, phase):
    air_color = air_temperature_color(state["air_temp"])
    water_color = water_temperature_color(state["water_temp"])
    return render.Stack(children = [
        rect(0, 0, WIDTH, HEIGHT, BLACK),
        wave_frame(state, phase),
        outlined_text_at(1, 0, state["name"], OFF_WHITE),
        rect(58, 1, 4, 4, rating_color(state["rating"])),
        sun_icon(1, 8, air_color),
        outlined_text_at(10, 7, "%d°" % rounded_int(state["air_temp"]), air_color),
        drop_icon(37, 9, water_color),
        outlined_text_at(46, 7, "%d°" % rounded_int(state["water_temp"]), water_color),
        outlined_text_at(21, 17, "%s'" % one_decimal(state["wave_height"]), WHITE, FONT_BIG),
    ])

def page_two(state):
    return render.Stack(children = [
        rect(0, 0, WIDTH, HEIGHT, BLACK),
        text_at(1, 0, state["name"], OFF_WHITE),
        rect(47, 1, 3, 3, rating_color(state["rating"])),
        text_at(52, 0, state["rating"], rating_color(state["rating"])),
        text_at(1, 7, "WAVE %s'" % one_decimal(state["wave_height"]), OCEAN_LIGHT),
        text_at(1, 13, "PER %dS" % rounded_int(state["period"]), FOAM),
        text_at(35, 13, "SW %s" % state["swell_direction"], FOAM),
        text_at(1, 19, "WIND %s %dKT" % (state["wind_direction"], rounded_int(state["wind_speed"])), OFF_WHITE),
        text_at(1, 25, "SUNSET %s" % state["sunset"], SUNSET),
    ])

GO_PHRASES = [
    "LOOKIN' FUN",
    "GET ON IT",
    "PRETTY CLEAN",
    "SOME JUICE",
    "WORTH A PADDLE",
    "DAWN PATROL?",
    "YEAH BUDDY",
    "SEND IT",
]
MEH_PHRASES = [
    "MIXED BAG",
    "COULD BE FUN",
    "KINDA BUMPY",
    "WORTH A LOOK",
    "PICK A WINDOW",
    "NOT TOO BAD",
    "LONGBOARD DAY",
    "MAYBE...",
]
SHIT_PHRASES = [
    "MAYBE COFFEE",
    "PRETTY MESSY",
    "NOT MUCH DOING",
    "BLOWN OUT",
    "LONGBOARD OR NAP",
    "NOPE.",
    "TRY LATER",
    "ROUGH OUT THERE",
]

def forecast_phrase(state):
    if state["rating"] == "GO":
        phrases = GO_PHRASES
    elif state["rating"] == "MEH":
        phrases = MEH_PHRASES
    else:
        phrases = SHIT_PHRASES
    seed = state["hour"] + int(state["wave_height"] * 10) + int(state["period"])
    return phrases[seed % len(phrases)]

SHARK_GO = [
    [
        ".....SSS......",
        "...SSSSSSS....",
        "SSSSSSKSSSS...",
        ".SSSSSKSSSSSS.",
        "...SSWWSSSSSSS",
        "....SSSSSSSS..",
        ".....SS..SS...",
        "....S......S..",
    ],
    [
        "....SSSS......",
        "..SSSSSSSS....",
        "SSSSSKKSSSS...",
        ".SSSSKKSSSSSS.",
        "...SSWWSSSSSSS",
        "....SSSSSSSS..",
        "...SSS....SS..",
        "..S.........S.",
    ],
    [
        "......SS......",
        "...SSSSSSS....",
        "SSSSSSKSSSSSS.",
        ".SSSSSKSSSSSSS",
        "...SSWWSSSSSS.",
        "....SSSSSSS...",
        "..SSS....SS...",
        ".S..........S.",
    ],
]

SHARK_MEH = [
    [
        ".....SSS......",
        "...SSSSSSS....",
        "SSSSSSKSSSS...",
        ".SSSSSSSSSSSS.",
        "...SSWWSSSSSSS",
        "....SSSSSSSS..",
        ".....SS..SS...",
        "....S......S..",
    ],
    [
        "....SSS.......",
        "..SSSSSSSS....",
        "SSSSSSKSSSS...",
        ".SSSSSSSSSSSS.",
        "...SSWWSSSSSS.",
        "....SSSSSSS...",
        "......S...SS..",
        ".....S......S.",
    ],
    [
        "......SSS.....",
        "...SSSSSSS....",
        "SSSSSSKSSSS...",
        ".SSSSSSSSSSSS.",
        "...SSWWSSSSSSS",
        "....SSSSSSSS..",
        "...SS......S..",
        "..S.........S.",
    ],
]

SHARK_SHIT = [
    [
        "..G..SSS...G..",
        "...SSSSSSS....",
        "SSSSSSKSSSS...",
        ".SSSSSSSSSSSS.",
        "...SSWWSSSSSSS",
        "....SSSSSSSS..",
        ".F...SS..SS.F.",
        "F...S......S.F",
    ],
    [
        "F...SSSS....F.",
        "..SSSSSSSS....",
        "SSSSSSKSSSS...",
        ".SSSSSSSSSSSS.",
        "...SSWWSSSSSS.",
        "F...SSSSSSS..F",
        "...SS.....SS..",
        "..S.........S.",
    ],
    [
        ".G....SS...G..",
        "...SSSSSSS....",
        "SSSSSSKSSSSSS.",
        ".SSSSSSSSSSSSS",
        "...SSWWSSSSSS.",
        "..F.SSSSSSS.F.",
        ".FSSS....SS...",
        "F.S..........F",
    ],
]

def sprite(pattern, x, y):
    pixels = []
    for row in range(len(pattern)):
        line = pattern[row]
        for col in range(len(line)):
            ch = line[col:col + 1]
            color = None
            if ch == "S":
                color = SHARK
            elif ch == "W":
                color = SHARK_LIGHT
            elif ch == "K":
                color = BLACK
            elif ch == "G":
                color = SEAWEED
            elif ch == "F":
                color = FOAM
            if color:
                pixels.append(rect(x + col, y + row, 1, 1, color))
    return render.Stack(children = pixels)

def shark_for(state, frame_index):
    seed = state["hour"] + int(state["wave_height"] * 10)
    variant = seed % 3
    bob = 1 if frame_index % 4 >= 2 else 0
    if state["rating"] == "GO":
        pattern = SHARK_GO[variant]
    elif state["rating"] == "MEH":
        pattern = SHARK_MEH[variant]
    else:
        pattern = SHARK_SHIT[variant]
    return sprite(pattern, 48, 22 + bob)

def page_three(state, frame_index):
    return render.Stack(children = [
        rect(0, 0, WIDTH, HEIGHT, BLACK),
        text_at(1, 0, forecast_phrase(state), rating_color(state["rating"])),
        text_at(1, 7, "%s' @ %dS %s" % (one_decimal(state["wave_height"]), rounded_int(state["period"]), state["swell_direction"]), FOAM),
        text_at(1, 13, "WIND %s %dKT" % (state["wind_direction"], rounded_int(state["wind_speed"])), OFF_WHITE),
        text_at(1, 19, state["trend"], OCEAN_LIGHT if state["trend"] != "HOLDING" else MEH),
        shark_for(state, frame_index),
    ])

def error_page():
    return render.Stack(children = [
        rect(0, 0, WIDTH, HEIGHT, BLACK),
        text_at(5, 6, "SHARKBYTE SURF", OCEAN_LIGHT),
        text_at(8, 14, "DATA'S TAKING", OFF_WHITE),
        text_at(13, 21, "A BREAK...", MEH),
    ])

def repeated_wave_frames(state):
    period_seconds = clamp(rounded_int(state["period"]), 6, 18)
    total_frames = period_seconds * int(1000 / FRAME_MS)
    result = []
    for i in range(total_frames):
        phase = int(float(i) / float(max(1, total_frames - 1)) * float(WAVE_PHASES - 1))
        result.append(page_one(state, phase))
    return result

def main(config):
    preferred_min = float(config.str("preferred_min", "1.5"))
    preferred_max = float(config.str("preferred_max", "6"))
    spots = active_spots(config)

    states = []
    for spot in spots:
        state = get_state(spot, preferred_min, preferred_max)
        if state:
            states.append(state)

    if not states:
        return render.Root(
            child = error_page(),
            delay = 1000,
            show_full_animation = True,
        )

    frames = []
    for state in states:
        frames += repeated_wave_frames(state)

    primary = states[0]

    if config.bool("show_details", True):
        frames += [page_two(primary) for _ in range(20)]

    if config.bool("show_summary", True):
        frames += [page_three(primary, i) for i in range(24)]

    return render.Root(
        child = render.Animation(children = frames),
        delay = FRAME_MS,
        show_full_animation = True,
    )

def get_schema():
    fields = [
        schema.Text(
            id = "spot1_name",
            name = "Saved Spot 1 name",
            desc = "Name shown on the display.",
            icon = "water",
            default = "BLACKIES",
        ),
        schema.Text(
            id = "spot1_coords",
            name = "Saved Spot 1 coordinates",
            desc = "Latitude,longitude. Example: 33.608879,-117.929205",
            icon = "locationDot",
            default = "33.608879,-117.929205",
        ),
    ]

    for slot in range(2, 7):
        fields += [
            schema.Text(
                id = "spot%d_name" % slot,
                name = "Saved Spot %d name" % slot,
                desc = "Optional saved surf spot name.",
                icon = "water",
                default = "",
            ),
            schema.Text(
                id = "spot%d_coords" % slot,
                name = "Saved Spot %d coordinates" % slot,
                desc = "Latitude,longitude. Leave blank if unused.",
                icon = "locationDot",
                default = "",
            ),
        ]

    fields += [
        schema.Dropdown(
            id = "active1",
            name = "Active Spot 1 (primary)",
            desc = "Page 1 rotates through active spots. Details and forecast use this primary spot.",
            icon = "locationDot",
            options = SLOT_OPTIONS,
            default = "1",
        ),
        schema.Dropdown(
            id = "active2",
            name = "Active Spot 2",
            desc = "Optional second spot in the Page 1 rotation.",
            icon = "locationDot",
            options = SECONDARY_SLOT_OPTIONS,
            default = "0",
        ),
        schema.Dropdown(
            id = "active3",
            name = "Active Spot 3",
            desc = "Optional third spot in the Page 1 rotation.",
            icon = "locationDot",
            options = SECONDARY_SLOT_OPTIONS,
            default = "0",
        ),
        schema.Dropdown(
            id = "preferred_min",
            name = "Preferred surf minimum",
            desc = "Used only for the GO / MEH / SHIT quality indicator.",
            icon = "arrowDown",
            options = MIN_OPTIONS,
            default = "1.5",
        ),
        schema.Dropdown(
            id = "preferred_max",
            name = "Preferred surf maximum",
            desc = "Used only for the GO / MEH / SHIT quality indicator.",
            icon = "arrowUp",
            options = MAX_OPTIONS,
            default = "6",
        ),
        schema.Toggle(
            id = "show_details",
            name = "Details page",
            desc = "Show period, swell, wind, sunset, and the written condition rating.",
            icon = "list",
            default = True,
        ),
        schema.Toggle(
            id = "show_summary",
            name = "Shark forecast",
            desc = "Show the reactive shark mascot and rotating surfer-speak summary.",
            icon = "fishFins",
            default = True,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = fields,
    )
