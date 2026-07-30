#!/bin/sh
# wttr.in weather fetcher for the waybar `custom/weather` module.
#
# No API key — location is pinned in $URL (Camberley, Surrey, UK) so it's
# stable regardless of egress IP / VPN. Emits waybar JSON so we can set both
# the pill text and a multi-line Pango tooltip.
#
#   {"text":"<icon> <temp> <condition>","tooltip":"<rich pango markup>","class":"weather"}
#
# The tooltip is a rich, themed overlay — the same idea as the tailscale pill's
# tooltip: a bold condition line, temp/feels-like, then labeled Wind / Humidity
# / Location rows, all colored with the warm-metal @define-color palette so it
# reads as part of the bar rather than a generic popup. It appears on hover,
# exactly like the tailscale overlay.
#
# The icon is a Nerd Font glyph (nf-weather-*) mapped from the condition text,
# NOT wttr.in's color emoji — color emoji render ~50px tall and force the bar
# above its 38px height, and they clash with the monochrome nerd-font icons
# used everywhere else. Temperature coloring (hot/cold Pango spans) reuses
# the same idiom as sysinfo.sh's cputemp.
#
# We pull the j1 (JSON) payload instead of the plain `format=` string so we
# get feels-like, humidity, and wind for the tooltip in one request.
#
# Fault tolerance: wttr.in is rate-limited and occasionally slow/flaky, so a
# good result is cached to /tmp and reused when a fetch fails — a transient
# network blip never blanks or shifts the pill. If there is no cache either,
# emit a stable placeholder so the pill keeps its width.

CACHE="${TMPDIR:-/tmp}/waybar-weather.json"
# Fixed location — wttr.in otherwise geo-locates by IP, which drifts to wherever
# the egress IP resolves (and is wrong on a VPN/exit node). Use the city name so
# wttr.in resolves the coordinates; nearest_area in the j1 payload then reports
# Camberley, Surrey, England for the tooltip's Location row.
URL='https://wttr.in/Camberley,Surrey,UK?format=j1'
MAX_AGE=$((9 * 60))   # reuse cache up to 9 min (interval is 600s; avoids refetch storms)

# Warm-metal tooltip colors — mirror the @define-color values in style.css so
# the tooltip reads as part of the theme, exactly like the tailscale pill.
LABEL_C='#e8c272'   # @gold     — labels / bold condition
VALUE_C='#f0e6d2'   # @text     — primary values
DIM_C='#937c63'     # @overlay0 — location
HOT_C='#ed8796'     # hot  >=30C
COLD_C='#8aadf4'    # cold <=0C

# Map a wttr.in condition string to a Nerd Font weather glyph.
icon_for() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    *sunny*|*clear*)            echo "" ;;  # nf-weather-day_sunny
    *partly*cloudy*|*partly*)    echo "" ;;  # nf-weather-day_cloudy
    *cloudy*|*overcast*)        echo "" ;;  # nf-weather-cloudy
    *mist*|*fog*|*haze*)         echo "" ;;  # nf-weather-fog
    *drizzle*|*rain*)           echo "" ;;  # nf-weather-rain
    *snow*|*sleet*|*ice*)       echo "" ;;  # nf-weather-snowflake_cold
    *thunder*|*storm*)          echo "" ;;  # nf-weather-thunderstorm
    *wind*)                     echo "" ;;  # nf-weather-windy
    *)                          echo "" ;;  # nf-weather-day_cloudy (fallback)
  esac
}

emit() {  # text tooltip  — --arg escapes newlines/quotes safely
  jq -cn --arg text "$1" --arg tooltip "$2" \
    '{text:$text,tooltip:$tooltip,class:"weather"}'
}

# Serve a not-too-stale cache without hitting the network.
if [ -f "$CACHE" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
  [ "$age" -lt "$MAX_AGE" ] && { cat "$CACHE"; exit 0; }
fi

raw=$(curl -s --max-time 10 "$URL" 2>/dev/null)

if [ -n "$raw" ] && printf '%s' "$raw" | jq -e '.current_condition[0]' >/dev/null 2>&1; then
  cc='.current_condition[0]'
  temp=$(printf '%s' "$raw" | jq -r "$cc.temp_C")
  feels=$(printf '%s' "$raw" | jq -r "$cc.FeelsLikeC")
  cond=$(printf '%s' "$raw" | jq -r "$cc.weatherDesc[0].value")
  hum=$(printf '%s' "$raw" | jq -r "$cc.humidity")
  wind=$(printf '%s' "$raw" | jq -r "$cc.windspeedKmph")
  winddir=$(printf '%s' "$raw" | jq -r "$cc.winddir16Point")
  loc=$(printf '%s' "$raw" | jq -r '.nearest_area[0].areaName[0].value // empty')
  region=$(printf '%s' "$raw" | jq -r '.nearest_area[0].region[0].value // empty')
  icon=$(icon_for "$cond")

  # Color the pill temperature: hot >=30 red, cold <=0 blue, else leave plain.
  case "$temp" in
    ''|*[!0-9-]*) colored="$temp°C" ;;
    *)
      if [ "$temp" -ge 30 ];  then colored="<span color='$HOT_C'>$temp°C</span>"
      elif [ "$temp" -le 0 ]; then colored="<span color='$COLD_C'>$temp°C</span>"
      else colored="$temp°C"; fi ;;
  esac

  text="$icon $colored $cond"

  # Rich themed tooltip — bold condition, temp/feels, then labeled rows.
  # Location is dimmed; missing region collapses to just the city.
  where=$loc; [ -n "$region" ] && where="$loc, $region"
  tooltip=$(printf \
    '<span color="%s"><b>%s</b></span>\n<span color="%s">%s°C (feels %s°C)</span>\n\n<span color="%s">Wind:</span> %s km/h %s\n<span color="%s">Humidity:</span> %s%%\n<span color="%s">Location:</span> <span color="%s">%s</span>' \
    "$LABEL_C" "$cond" "$VALUE_C" "$temp" "$feels" \
    "$LABEL_C" "$wind" "$winddir" \
    "$LABEL_C" "$hum" \
    "$LABEL_C" "$DIM_C" "$where")

  emit "$text" "$tooltip" | tee "$CACHE"
else
  # Fetch failed: fall back to cache if present, else a stable placeholder.
  if [ -f "$CACHE" ]; then cat "$CACHE"; else emit "  N/A" "Weather unavailable"; fi
fi