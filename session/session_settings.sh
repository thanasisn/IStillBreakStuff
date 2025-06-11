#!/usr/bin/env bash
## created on 2021-11-16

#### Set session options for monitors keyboard touchpad ...

set +e

## screen lock option
case "$(hostname)" in
    "mumra")
        echo "mumra"
        savertime=1100
        ;;

    "tyler")
        echo "tyler"
        savertime=900
        ;;

    "sagan")
        echo "sagan"
        savertime=500
        ;;

    *)
        echo "any host"
        savertime=600
        ;;
esac
echo

echo "-- screen saver and locking --"
xset s $savertime $savertime
echo xset s $savertime $savertime
echo

echo "- - - Set monitors standby suspend off - - - "
time=3000
echo xset dpms $time $(( time + 120)) $((time + 160))
xset dpms $time $(( time + 120)) $((time + 160))
echo

echo " - - - Keyboard repeat rate - - - "
echo xset r rate 300 45
xset r rate 300 45
echo

echo " - - - Current xset config - - - "
xset q
echo

if type synclient >/dev/null 2>&1; then
  echo " - - - Set touchpad options - - - "
  synclient  VertEdgeScroll=1
  synclient  TapButton1=1
  synclient  TapButton2=1      # why on tyler
  synclient  LBCornerButton=1
  synclient  RBCornerButton=1
  echo
fi

echo "Set keyboard language options"
#  setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,el
setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr
echo

echo "Swap caps and escape keys"
setxkbmap -option "caps:swapescape"
echo


exit 0
