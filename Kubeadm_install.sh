#!/bin/bash

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

function download_CRI_Extract_Run() {
    OS=$(uname)
    ARCH=$(uname -p)
    Version="1.6.4"
    if [ $ARCH == "x86_64" ]; then
        ARCH="amd64"
    fi

    if test -f /usr/local/bin/containerd; then
        printf "Output: Containerd(CRI) already downloaded and extracted\n"
    else
        URL_containerd="https://github.com/containerd/containerd/releases/download/v$Version/containerd-$Version-$OS-$ARCH.tar.gz"
        wget $URL_containerd
        Containerd_File="containerd-$Version-$OS-$ARCH.tar.gz"
        sudo tar Czxvf /usr/local $Containerd_File
        rm $Containerd_File
    fi

    if test -f /etc/systemd/system/containerd.service; then
        printf "Output: Unit file already downloaded and moved\n"
    else
        URL_UnitFile="https://raw.githubusercontent.com/containerd/containerd/main/containerd.service"
        wget $URL_UnitFile
        sudo mv containerd.service /etc/systemd/system
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable --now containerd

    if [ $(systemctl is-active containerd) == "active" ]; then
        printf "Output: Containerd service is Running, check with: systemctl status containerd\n\n"
    fi
}

function userInput() {
    read USERINPUT

    if [ $USERINPUT == 1 ]; then
        turn_Off_Memory_Swap "sudo sudo swapoff -a" "@reboot sudo swapoff -a" "/var/spool/cron/crontabs/root"
    elif [ $USERINPUT == 2 ]; then
        download_CRI_Extract_Run

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
2.Download Containerd(CRI) version 1.6.4

Input:"
}

showMenu
userInput
