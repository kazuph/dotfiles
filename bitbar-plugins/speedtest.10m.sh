#!/usr/local/bin/zsh -l
res=($(speedtest-cli --simple | cut -d' ' -f2 | cut -d. -f1 | xargs echo))

echo "⬇$res[2]⬆$res[3]"
echo "---"
echo "ping: $res[1][ms]"
echo "download: $res[2][Mbps]"
echo "upload: $res[3][Mbps]"
