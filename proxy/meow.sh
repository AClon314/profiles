#! /bin/bash
dir_config="/home/n/.config/mihomo"
cd metacubexd
exec ~/.bun/bin/http-server & PID=$!

cleanup() {
  kill $PID
  sudo pkill mihomo
}
trap cleanup EXIT

pgrep -fl mihomo && wait || sudo mihomo -d $dir_config
