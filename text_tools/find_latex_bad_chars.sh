#!/bin/bash
## created on 2021-12-15

#### Find non ascii characters, offending base latex

grep -n -P "[^|a-zA-Z\{\}\s%\./\-:;,0-9@=\\\\\"'\(\)_~\$\!&\`\?+#\^<>\[\]\*]" $@

exit 0 
