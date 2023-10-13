#!/usr/bin/env bash

LOCAL_DATA_DIR=/azerothcore/env/dist/data

localDataVersionFile="$LOCAL_DATA_DIR/data-version"
[ -f "$localDataVersionFile" ] && source "$localDataVersionFile"
LOCAL_VERSION=$INSTALLED_VERSION

INSTALLED_VERSION=""
dataVersionFile="$DATAPATH/data-version"
[ -f "$dataVersionFile" ] && source "$dataVersionFile"

if [ "$LOCAL_VERSION" == "$INSTALLED_VERSION" ]; then
    echo "Data $LOCAL_VERSION already installed. If you want to force the copy remove the following file: $dataVersionFile"
    exit 0
fi

cp --verbose -r $LOCAL_DATA_DIR/* $DATAPATH/
