#!/bin/sh
# wttr.in weather fetcher for the waybar `custom/weather` module.
#
# No API key, no location config — wttr.in geo-locates by IP. Emits waybar
# JSON so we can set both the pill text and a multi-line tooltip. Output:
#
#   {"text":"<icon> <temp> <condition>","tooltip":"<condition>\n<location>","class":"weather"}
#
# The icon is a Nerd Font glyph (nf-weather-*) mapped from the condition text,
# NOT wttr.in's color emoji — color emoji render ~50px tall and force the bar
# above its 38px height, and they clash with the monochrome nerd-font icons
# used everywhere else. Temperature coloring (hot/cold Pango spans) reuses
# the same idiom as sysinfo.sh's cputemp.
#
# Fault tolerance: wttr.in is rate-limited and occasionally slow/flaky, so a
# good result is cached to /tmp and reused when a fetch fails — a transient
# network blip never blanks or shifts the pill. If there is no cache either,
# emit a stable placeholder so the pill keeps its width.

CACHE="${TMPDIR:-/tmp}/waybar-weather.json"
URL='https://wttr.in/?format=%t|%C|%l'
MAX_AGE=$((9 * 60))   # reuse cache up to 9 min (interval is 600s; avoids refetch storms)

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

if [ -n "$raw" ]; then
  temp=$(printf '%s' "$raw" | cut -d'|' -f1 | tr -d '+')
  cond=$(printf '%s' "$raw" | cut -d'|' -f2)
  loc=$(printf '%s' "$raw" | cut -d'|' -f3)
  icon=$(icon_for "$cond")

  # Color the temperature: hot >=30 red, cold <=0 blue, else leave plain.
  tnum=$(printf '%s' "$temp" | tr -dc '0-9-')
  case "$tnum" in
    ''|*[!0-9-]*) colored="$temp" ;;
    *)
      if [ "$tnum" -ge 30 ];  then colored="<span color='#ed8796'>$temp</span>"
      elif [ "$tnum" -le 0 ]; then colored="<span color='#8aadf4'>$temp</span>"
      else colored="$temp"; fi ;;
  esac

  text="$icon $colored $cond"
  tooltip="$cond"$'\n'"$loc"
  emit "$text" "$tooltip" | tee "$CACHE"
else
  # Fetch failed: fall back to cache if present, else a stable placeholder.
  if [ -f "$CACHE" ]; then cat "$CACHE"; else emit "  N/A" "Weather unavailable"; fi
fi