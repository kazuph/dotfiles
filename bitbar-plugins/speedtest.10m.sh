#!/opt/homebrew/bin/zsh
res=($(/opt/homebrew/bin/speedtest-cli --simple | cut -d' ' -f2 | cut -d. -f1 | xargs echo))

echo "\r⬇$res[2]⬆$res[3]"
echo "---"
echo "ping: $res[1][ms]"
echo "download: $res[2][Mbps]"
echo "upload: $res[3][Mbps]"

. ./.env

url=$SPEEDTEST_API_URL
curl $url \
    -XPOST \
    -s \
    -d net_speed_ping=$res[1] \
    -d net_speed_download=$res[2] \
    -d net_speed_upload=$res[3] > /dev/null
