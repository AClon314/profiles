#!/bin/bash
# USER=n

uninstall() {
  ls /home/$USER/.cargo/bin | xargs -I % sudo rm /usr/local/bin/%
  sudo rm /root/.cargo
  sudo rm /root/.rustup
}

install() {
  sudo ln -s /home/$USER/.cargo/bin/* /usr/local/bin/
  sudo ln -s /home/$USER/.cargo /root/.cargo
  sudo ln -s /home/$USER/.rustup /root/.rustup
}

uninstall
install

if [ "$1" == "u" ]; then
  uninstall
fi
