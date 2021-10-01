#!/bin/bash
## https://github.com/thanasisn <lapauththanasis@gmail.com>


#### Throttle a process cpu usage according to cpu temperature

# require:
#   lm-sensors
#   cpulimit

max_limit=80          ## temperature limit to match
targetpid=9999999999  ## processes id to monitor
cputhresshold=60      ## assume we start at 60% of cpu
cpustep=5             ## the step down
waittemp=20           ## wait for equilibrium
maxout=40             ## suspend or kill if can not reach safe temp after these tries
cntout=0
cpulimit_PID=fooo     ## capture the pid of cpulimit
temp_margin=1         ## allow some space to reduce racing


## TODO read variables from elsewhere in order to change options while running

## Inputs and checks
targetpid=""
while [[ ! $targetpid =~ ^[0-9]+$ ]]; do
    echo "Enter process PID to throttle"
    read targetpid
done

max_limit=""
while [[ ! $max_limit =~ ^[0-9]+$ ]]; do
    echo "Enter max temperature target"
    read max_limit
done

if ps -p $targetpid > /dev/null ; then
   echo "Process $targetpid exist"
   pros_name="$(ps -p $targetpid -o cmd | tail -1)"
   echo $pros_name
else
    echo "Process $targetpid does not exist."
    exit 3
fi


## start throttling

pros_name="$(ps -p $targetpid -o cmd | tail -1)"
while true; do

    ## get temperature
    max_value=$(sensors | grep "Core" | sed 's/ \+/ /g' | cut -d' ' -f3 | grep -o '[0-9]\+' | sort | tail -1)

    echo "$pros_name"
    echo ""
    echo "Target temperature:   $max_limit C"
    echo "Max current tempera:  $max_value C"

    ## too hot
    upper_lim=$((max_limit+temp_margin))
    lower_lim=$((max_limit-temp_margin))
    if [[ $max_value -gt $upper_lim ]]; then
        ## count limit ups
        cntout=$((cntout+1))
        echo "TOO HOT count:        $cntout"
        if [[ $cntout -ge $maxout ]];then
            echo "no cooling"
            echo "Have to kill everything"
            echo "kill $targetpid "
            kill -9 $targetpid
            echo "exit"
            exit 9
        fi

        ## step down
        cputhresshold=$((cputhresshold-cpustep))
        if [[ "$cputhresshold" -le 0 ]];then
            cputhresshold=$cpustep
        fi
        echo "Current threshold:    ${cputhresshold}% / ${upper_lim} %"

        ## kill previus cpulimit
        kill $cpulimit_PID
        cpulimit -q -z -p $targetpid -l $cputhresshold  &
        cpulimit_PID=$!

        echo ""
        echo "wait for temperature drop"

    elif [[ "$max_value" < "$lower_lim" ]]; then
        echo "not too hot"
        ## reset limit up counter
        cntout=0

        ## step up
        cputhresshold=$((cputhresshold+cpustep))
        if [[ "$cputhresshold" -ge 100 ]];then
            cputhresshold=100
        fi
        echo "Current threshold:    ${cputhresshold}% / ${upper_lim} %"

        ## kill previous cpulimit
        kill $cpulimit_PID
        cpulimit -q -z -p $targetpid -l $cputhresshold  &
        cpulimit_PID=$!

        echo ""
        echo "wait for temperature rise"
    else
        echo "Current threshold:    $cputhresshold %"
        echo "Nominal temperature"

    fi

    if ps -p $targetpid > /dev/null ; then
        echo "Process $targetpid still exist"
    else
        echo "Process $targetpid does not exist any more."
        exit 0
    fi

    sleep $waittemp
    clear
done


exit 0
