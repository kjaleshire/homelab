#!/bin/bash
# https://github.com/transmission/transmission/blob/main/docs/Scripts.md
set -euo pipefail
# TELEGRAM_TOKEN <- set in secret
# TELEGRAM_CHAT_ID <- set in secret

# strips whitespace
TR_TIME_LOCALTIME=$(echo $TR_TIME_LOCALTIME | xargs)

# MESSAGE="$TR_TORRENT_NAME has finished downloading at $TR_TIME_LOCALTIME."
MESSAGE="A torrent has finished downloading at $TR_TIME_LOCALTIME."
curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE" > /dev/null
