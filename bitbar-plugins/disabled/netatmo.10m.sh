#!/usr/local/bin/zsh -l
# https://dev.netatmo.com/myaccount/createanapp
. $(dirname $0)/.env

NETATMO_API_TOKEN=$(curl -sX POST https://api.netatmo.com/oauth2/token -d "grant_type=password&client_id=${NETATMO_CLIENT_ID}&client_secret=${NETATMO_CLIENT_SECRET}&username=${NETATMO_USER_NAME}&password=${NETATMO_PASSWORD}" | jq -r ".access_token")


# Data Example
# {
#   "time_utc": 1573095642,
#   "Temperature": 22.5,
#   "CO2": 1522,
#   "Humidity": 49,
#   "Noise": 59,
#   "Pressure": 1019.7,
#   "AbsolutePressure": 1017.5,
#   "min_temp": 20.9,
#   "max_temp": 29.8,
#   "date_max_temp": 1573090515,
#   "date_min_temp": 1573085223,
#   "temp_trend": "stable"
# }
data=$(curl -sX GET "https://api.netatmo.com/api/getstationsdata?access_token=${NETATMO_API_TOKEN}" | jq -c ".body.devices[0].dashboard_data")

temperature=$(jq -r ".Temperature" <<<"$data")
co2=$(jq -r ".CO2" <<<"$data")
humidity=$(jq -r ".Humidity" <<<"$data")
noise=$(jq -r ".Noise" <<<"$data")
pressure=$(jq -r ".Pressure" <<<"$data")

echo "CO2: " $co2 "ppm"
echo "---"
echo "温度: " $temperature "℃"
echo "湿度: " $humidity "％"
echo "騒音: " $noise "dB"
echo "気圧: " $pressure "mb"
