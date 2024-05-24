#!/bin/bash
UE_PLUGIN=/home/n/download/UE_5.4.1/Engine/Plugins

find $UE_PLUGIN -type l -exec test ! -e {} \; -delete # remove broken links
readlink -f ./*/data/Engine/Plugins/* | xargs -I % ln -s % $UE_PLUGIN
exec nemo /home/n/download/UE_5.4.1/Engine/Plugins

# Place me under ~/document/Epicvalt/ (Epic Asset Manager's Default path)