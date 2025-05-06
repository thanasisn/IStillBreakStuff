#!/usr/bin/env bash
## created on 2024-03-02

#### Heartbeat of host to telegram

## ignore errors
set +e

## Get telegram credentials  ---------------------------------------------------
if [ -f ~/.ssh/telegram/unikey_$(hostname) ]; then
    . ~/.ssh/telegram/unikey_$(hostname)
  else
    . ~/.ssh/telegram/unikey_hosts
fi

## Try to use markdown first  --------------------------------------------------

## create the message to send
mes="$(hostname) $(date +'%F %T')
\`\`\`
$(uptime -p)
L: $(cat /proc/loadavg)
T: $(ps -e | wc -l)
$(free -h)

$(w)

$(df -Th -x tmpfs -x devtmpfs -x squashfs)

$(sensors -A)
\`\`\`
"

echo
## escape characters
mes="$(echo "$mes" |  sed -e 's/[-()&]/\\&/g')"
echo "$mes"

## post
curl -s -X POST                                             \
  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
  -d parse_mode='MarkdownV2'                                \
  -d chat_id="$TELEGRAM_ID"                                 \
  -d text="$mes"

## if succeed exit
if [ $? -eq 0 ]; then
  echo
  echo "OK"
  exit 0
else
  echo "Markdown failed, trying plain"
fi


## Use plain text if markdown fails  -------------------------------------------

## create the message to send
mes="$(hostname) $(date +'%F %T')
$(uptime -p)
L: $(cat /proc/loadavg)
T: $(ps -e | wc -l)
$(free -h)

$(w)

$(df -Th -x tmpfs -x devtmpfs -x squashfs)

$(sensors -A)
"

## post
echo
echo "$mes"
curl -s -X POST                                             \
  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
  -d chat_id="$TELEGRAM_ID"                                 \
  -d text="$mes"




exit 0
