#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# KawaCoder@duck.com

# Check for required arguments
if [ $# -eq 0 ]; then
    echo "./plane_spotter.sh latitude longitude"
    echo "Example: ./plane_spotter.sh 48.8554 2.3459"
    exit 1
fi

function display_banner() {
    echo -e "
 _________________________          _____
|                         \          \ U \__      _____
|      Plane Spotter       \__________\   \/_______\___\________________
|     -By KawaCoder-       /          &lt; /_/   .....................  \`-.
|_________________________/            \`-----------,----,---------------'
                                                 _/____/
Feel free to hack
Uses OpenSky API and Open-Meteo API.
"
}

display_banner

# Constants
LATITUDE="$1"
LONGITUDE="$2"
VALUE_INDEX=20
R_EARTH=6378
PI=3.1415

# Weather and flight data indices
declare -A DATA_INDICES=(
    ["latitude"]=6
    ["longitude"]=5
    ["geo_altitude"]=13
)

# Convert degrees to radians
deg2rad() {
    echo "scale=10; $1 * 4 * a(1) / 180" | bc -l
}

# Calculate distance between two points in kilometers
get_distance_from_lat_lon_in_km() {
    local lat1="$1" lon1="$2" lat2="$3" lon2="$4" R=6371
    local dLat=$(deg2rad $(echo "$lat2 - $lat1" | bc -l))
    local dLon=$(deg2rad $(echo "$lon2 - $lon1" | bc -l))
    local a=$(echo "s($dLat/2) * s($dLat/2) + c($(deg2rad $lat1)) * c($(deg2rad "$lat2")) * s($dLon/2) * s($dLon/2)" | bc -l)
    local c=$(echo "2 * a(sqrt($a) / sqrt(1-$a))" | bc -l)
    local d=$(echo "$R * $c" | bc -l)
    echo "$d"
}

# Calculate longitude delta
calculate_delta_longitude() {
    local dx="$1"
    echo "scale=4;$LONGITUDE + ($dx / $R_EARTH) * (180 / $PI) / c($LATITUDE * $PI / 180)" | bc -l
}

# Calculate latitude delta
calculate_delta_latitude() {
    local dy="$1"
    echo "scale=4;$LATITUDE + ($dy / $R_EARTH) * (180 / $PI)" | bc -l
}

# Fetch weather data
weather_data=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,visibility")

# Parse weather data
visibility=$(echo "$weather_data" | jq -r .hourly.visibility[$VALUE_INDEX])
high_limit="$visibility"
low_limit=500
cloud_cover=$(echo "$weather_data" | jq -r .hourly.cloud_cover[$VALUE_INDEX])
cloud_cover_low=$(echo "$weather_data" | jq -r .hourly.cloud_cover_low[$VALUE_INDEX])
cloud_cover_mid=$(echo "$weather_data" | jq -r .hourly.cloud_cover_mid[$VALUE_INDEX])
cloud_cover_high=$(echo "$weather_data" | jq -r .hourly.cloud_cover_high[$VALUE_INDEX])

# Display weather data
echo -e "\n\033[0;34mVisibility_______________________\033[0m"
echo -e "\nCurrent visibility:                   ${visibility}m"
echo -e " \n\n\033[0;32mCloud data_______________________\033[0m"
echo  -e "\nCurrent cloud coverage:               ${cloud_cover}%"
echo " --> Current cloud coverage 0-3km:    ${cloud_cover_low}%"
echo " --> Current cloud coverage 3-8km:    ${cloud_cover_mid}%"
echo -e " --> Current cloud coverage >8km:     ${cloud_cover_high}%\n"

# Adjust high altitude limit based on cloud cover
visibility=$(( visibility/1000 ))
visibility_neg=$(( -visibility ))
if [[ $cloud_cover -gt 50 ]]; then
    echo -e "\033[0;31m /!\\ \033[0m Poor visibility. Setting high altitude limit:"
    if [[ $cloud_cover_low -gt 50 ]]; then
        echo -e "\nHigh limit set to 3 km.\n"
        high_limit=3000
    elif [[ $cloud_cover_mid -gt 50 ]]; then
        echo "High limit set to 5 km."
        high_limit=5000
    elif [[ $cloud_cover_high -gt 50 ]]; then
        echo "High limit set to 8 km."
        high_limit=8000
    fi
fi

# Calculate geographic bounds
longitude_min=$(calculate_delta_longitude "$visibility_neg")
latitude_min=$(calculate_delta_latitude "$visibility_neg")
longitude_max=$(calculate_delta_longitude "$visibility")
latitude_max=$(calculate_delta_latitude "$visibility")

# Fetch plane data
plane_data=$(curl -s "https://opensky-network.org/api/states/all?lamin=${latitude_min}&lomin=${longitude_min}&lamax=${latitude_max}&lomax=${longitude_max}")

# Check plane data availability
number_of_planes=$(echo "$plane_data" | jq '.states | length')
if [ "$(echo "$plane_data" | jq '.states == null')" = "true" ]; then
    echo "No plane returned in this area."
    exit 0
fi

# Filter plane data by altitude limits
filtered_planes=$(echo "$plane_data" | jq --argjson low_limit "$low_limit" --argjson high_limit "$high_limit" '
  .states |= map(select(. != null and .[13] != null and .[13] >= $low_limit and .[13] <= $high_limit))
')

number_of_matching_planes=$(echo "$filtered_planes" | jq '.states | length')

# Display plane data
echo "High limit: $high_limit"
echo "Low limit: $low_limit"
echo "Planes inside area: ${number_of_planes}"
echo "Planes inside area AND visible: ${number_of_matching_planes}"
echo "$filtered_planes" | jq -r '
  .states | 
  to_entries[] | 
  "\n\([.key + 1]) Callsign: \(.value[1] | gsub(" "; "")) | Altitude: \(.value[13])m\nlink: https://www.flightaware.com/live/flight/\(.value[1] | gsub(" "; ""))"
'