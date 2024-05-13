. ./config.conf

BASE0=$(basename $0) 
FULL0="$(readlink -f "$0")"
DIR0=$(dirname $FULL0)

which looking-glass-client > /dev/null && echo "✔ Installed looking-glass-client" ||\
if [[ -z "$1" ]]; then
  echo "❌ Exit: You have to provide the path of looking-glass-client"
  echo "💡 Tips: run $0 skip to skip all error" | grep "$0 skip"
  exit 1
elif [[ "$1" == "skip" ]]; then
  echo "⚠️ Skipping cmake of looking-glass-client"
else
  pushd $1 &&\
  mkdir -p client/build &&\

  pushd client/build &&\
  cmake ../ &&\
  make install &&\
  echo "✔ Install looking-glass-client" &&\
  popd

  sudo apt-get install linux-headers-$(uname -r) dkms &&\
  pushd module/ &&\
  dkms install "." &&\
  echo "✔ Install dkms-kvmfr" || echo "❌ Error: Failed to install dkms-kvmfr"
fi

dkms status | grep kvmfr > /dev/null && echo "✔ Installed dkms-kvmfr" || echo "❌ Error: No dkms-kvmfr"
