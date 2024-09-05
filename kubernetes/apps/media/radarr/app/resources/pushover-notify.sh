#!/usr/bin/env bash
# shellcheck disable=SC2154

set -euo pipefail

# User defined variables for pushover
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-required}"
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-required}"
PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-"-2"}"

if [[ "${radarr_eventtype:-}" == "Test" ]]; then
    PUSHOVER_PRIORITY="1"
    PUSHOVER_URL=""
    PUSHOVER_URL_TITLE=""
    printf -v PUSHOVER_TITLE \
        "Test Notification"
    printf -v PUSHOVER_MESSAGE \
        "Howdy this is a test notification from %s" \
            "${radarr_instancename:-Sonarr}"
fi

if [[ "${radarr_eventtype:-}" == "Download" ]]; then
    printf -v PUSHOVER_TITLE \
        "Movie %s" \
            "$( [[ "${radarr_isupgrade}" == "True" ]] && echo "Upgraded" || echo "Downloaded" )"
    printf -v PUSHOVER_MESSAGE \
        "<b>%s (%s)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small><small>\n<b>Quality:</b> %s</small><small>\n<b>Size:</b> %s</small>" \
            "${radarr_movie_title}" \
            "${radarr_movie_year}" \
            "${radarr_movie_overview}" \
            "${radarr_download_client:-Unknown}" \
            "${radarr_moviefile_quality:-Unknown}" \
            "$(numfmt --to iec --format "%8.2f" "${radarr_release_size:-0}")"
    printf -v PUSHOVER_URL \
        "%s/movie/%s" \
            "${radarr_applicationurl:-localhost}" "${radarr_movie_tmdbid}"
    printf -v PUSHOVER_URL_TITLE \
        "View movie in %s" \
            "${radarr_instancename:-Radarr}"
fi

if [[ "${radarr_eventtype:-}" == "ManualInteractionRequired" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE \
        "Movie import requires intervention"
    printf -v PUSHOVER_MESSAGE \
        "<b>%s (%s)</b><small>\n<b>Client:</b> %s</small>" \
            "${radarr_movie_title}" \
            "${radarr_movie_year}" \
            "${radarr_download_client:-Unknown}"
    printf -v PUSHOVER_URL \
        "%s/activity/queue" \
            "${radarr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE \
        "View queue in %s" \
            "${radarr_instancename:-Radarr}"
fi

json_data=$(jo \
    token="${PUSHOVER_TOKEN}" \
    user="${PUSHOVER_USER_KEY}" \
    title="${PUSHOVER_TITLE}" \
    message="${PUSHOVER_MESSAGE}" \
    url="${PUSHOVER_URL}" \
    url_title="${PUSHOVER_URL_TITLE}" \
    priority="${PUSHOVER_PRIORITY}" \
    html="1"
)

status_code=$(curl \
    --silent \
    --write-out "%{http_code}" \
    --output /dev/null \
    --request POST  \
    --header "Content-Type: application/json" \
    --data-binary "${json_data}" \
    "https://api.pushover.net/1/messages.json" \
)

printf "pushover notification returned with HTTP status code %s and payload: %s\n" \
    "${status_code}" \
    "$(echo "${json_data}" | jq --compact-output)" >&2
