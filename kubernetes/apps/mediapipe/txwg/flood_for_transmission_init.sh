#!/bin/sh
set -euo pipefail
if [ -f /config/flood-for-transmission/index.html ]; then
    echo Flood already installed, skipping.
    echo If this is incorrect, re-install by removing /config/flood-for-transmission/index.html.
    exit 0
fi
echo Installation not found, downloading flood-for-transmission...
wget https://github.com/johman10/flood-for-transmission/releases/download/latest/flood-for-transmission.tar.gz
tar -C /config -xvzf flood-for-transmission.tar.gz
