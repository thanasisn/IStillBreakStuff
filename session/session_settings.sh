#!/usr/bin/env bash
## created on 2021-11-16

#### Set session options for monitors keyboard touchpad ...

set +e


echo " - - - Previous xset config - - -"
xset q
echo " - - - - - - - - - - - - - - - - "


echo "set monitors standby suspend off"
time=3000
echo xset dpms $time $(( time + 120)) $((time + 160))
xset dpms $time $(( time + 120)) $((time + 160))
echo " - - - - - - - - - - - - - - - - "


echo "keyboard repeat rate"
echo xset r rate 300 45
xset r rate 300 45
echo " - - - - - - - - - - - - - - - - "


echo " - - - Current xset config - - -"
xset q
echo " - - - - - - - - - - - - - - - - "


echo "set touchpad options"
synclient  VertEdgeScroll=1
synclient  TapButton1=1
synclient  TapButton2=1      # why on tyler
synclient  LBCornerButton=1
synclient  RBCornerButton=1
echo " - - - - - - - - - - - - - - - - "


echo "set keyboard language options"
setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,el

echo "swap caps and escape keys"
setxkbmap -option "caps:swapescape"
echo " - - - - - - - - - - - - - - - - "


exit 0
