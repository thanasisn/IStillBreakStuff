#!/usr/bin/env bash
## created on 2024-03-02

#### Heartbeat of host to telegram

## ignore errors
set +e

## Get telegram credentials
if [ -f ~/.ssh/telegram/unikey_$(hostname) ]; then
    . ~/.ssh/telegram/unikey_$(hostname)
  else
    TELEGRAM_TOKEN="7109742645:AAH4sya6BBpqS5xyh27lxGNLYzclvdZVRjI"
    TELEGRAM_ID="6849911952"
fi

## Try to use markdown first
mes="$(hostname) $(date +'%F %T')
\`\`\`
$(uptime -p)
L: $(cat /proc/loadavg)
T: $(ps -e | wc -l)
$(uptime | cut -d',' -f3  | sed 's/^[ ]*//')

$(free -h)

$(w)

$(df -Th -x tmpfs -x devtmpfs)

$(sensors -A)
\`\`\`
"

echo
## escape characters
mes="$(echo "$mes" |  sed -e 's/[-()&]/\\&/g')"
echo "$mes"

## post
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" -d parse_mode='MarkdownV2' -d chat_id="$TELEGRAM_ID" -d text="$mes"

## if succeed exit
if [ $? -eq 0 ]; then
  echo
  echo "OK"
  exit 0
else
  echo "Markdown failed, trying plain"
fi

## Use plain text if markdown fails
## create the message to send
mes="$(hostname) $(date +'%F %T')
$(uptime -p)
L: $(cat /proc/loadavg)
T: $(ps -e | wc -l)
M: $(free -h | awk '/Mem:/ { print $3 "/" $2 }')
$(uptime | cut -d',' -f3  | sed 's/^[ ]*//')
$(w -h)
$(df -Th -x tmpfs -x devtmpfs)
$(sensors -A)
"

echo
echo "$mes"
curl -s -X POST                                             \
  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
  -d chat_id="$TELEGRAM_ID"                                 \
  -d text="$mes"

mes="$(hostname) $(date +'%F %T')
\`\`\`
$(uptime -p)
L: $(cat /proc/loadavg)
T: $(ps -e | wc -l)
M: $(free -h | awk '/Mem:/ { print $3 "/" $2 }')
$(uptime | cut -d',' -f3  | sed 's/^[ ]*//')

$(w -h)

$(df -Th -x tmpfs -x devtmpfs)

$(sensors -A)
\`\`\`
"

echo
## escape characters
mes="$(echo "$mes" |  sed -e 's/[-()&]/\\&/g')"
echo "$mes"

curl -s -X POST                                             \
  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
  -d parse_mode='MarkdownV2'                                \
  -d chat_id="$TELEGRAM_ID"                                 \
  -d text="$mes"

exit 0
