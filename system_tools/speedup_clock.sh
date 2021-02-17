#!/bin/bash
## created on 2016-01-10

#### Speed up the time of a linux machine by adding a fixed amount of time at every interval
## This was used for testing a Sun tracker and the software I developed to control it for my research
## You can simulate a cycle of some days in few minutes
##
## WARNING: Of course this will skew all the times the machine clock reports to other programs!!
##


function finish {
    ## should restore correct time
    sudo ntpdate  -v gr.pool.ntp.org
    sudo /etc/init.d/ntp reload
    echo "bye"
}
trap finish EXIT

## The amount of time added at each interval
timstep=$((60*60))
## The interval of when the time step occurs
delay=5

echo ""
echo "    Time step:  $timstep sec"
echo "   Loop delay:  $delay sec"
echo ""

input=0
echo -n "Start faketime  (y/n)?: "
read -n 1 input
echo ""
if [ "$input" != "y" ] ; then
    exit
fi
# get current date stamp
startat=$(date +"%s")


cnt=0
while true; do
    let cnt+=1
    newdate=$((startat + cnt * timstep))

    # print date
    date -d @"$newdate" +"%F %R:%S"

    # set date
    date +%s -s @"$newdate" > /dev/null

    sleep $delay
done


exit 0
