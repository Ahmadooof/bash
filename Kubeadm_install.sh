
function turn_Off_Memory_Swap() {
    commandForCurrentSession="$1"
    commandForCronJob="$2"
    filePath="$3"

    # apply swap off for current session
    $commandForCurrentSession

    if grep -q "^$commandForCronJob" $filePath; then
        printf "Output: Already swap is off when reboot, check: $filePath\n\n"
    else
        #write out current crontab if exists in /var/spool/cron/crontabs
        crontab -l >mycron
        # echo new cron into cron file
        echo $commandForCronJob >>mycron
        #install new cron file
        crontab mycron
        # remove our cron file
        rm mycron
        printf "Output: Success\n\n"
    fi
}

function userInput() {
    read USERINPUT

    if [ $USERINPUT == 1 ]; then
      turn_Off_Memory_Swap "sudo sudo swapoff -a" "@reboot sudo swapoff -a" "/var/spool/cron/crontabs/root"
    elif [ $USERINPUT == 2]; then

    else
        printf "Output: Invalid character\n\n"
        showMenu
        userInput
    fi
}

function showMenu() {
    printf "
Choose a number:
1.Turn swap memory off (after reboot also will still off)
\n
Input:"
}

showMenu
userInput