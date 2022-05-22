#!/bin/bash

OS=$(uname)
ARCH=$(uname -p)
if [ $ARCH == "x86_64" ]; then
    ARCH="amd64"
fi
if [ $OS == "Linux" ]; then
    OS="linux"
fi

function turn_Off_Memory_Swap() {
    commandForCurrentSession="$1"
    commandForCronJob="$2"
    filePath="$3"

    if grep -q "^$commandForCronJob" $filePath; then
        printf "Output: Already swap is off after reboot, check to verify: $filePath\n\n"
    else
        # apply swap off for current session
        $commandForCurrentSession
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

function download_Extract_Run_CRI() {
    Version="1.6.4"

    if test -f /usr/local/bin/containerd; then
        printf "Output: Containerd(CRI) already downloaded and extracted check file to verify: /usr/local/bin/containerd\n"
    else
        URL_containerd="https://github.com/containerd/containerd/releases/download/v$Version/containerd-$Version-$OS-$ARCH.tar.gz"
        wget $URL_containerd
        Containerd_File="containerd-$Version-$OS-$ARCH.tar.gz"
        sudo tar Czxvf /usr/local $Containerd_File
        rm $Containerd_File
    fi

    if test -f /etc/systemd/system/containerd.service; then
        printf "Output: Unit file already downloaded and moved check to verify: /etc/systemd/system/containerd.service\n"
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

function download_Extract_Run_Runc() {
    Version="1.1.2"
    installedToPath="/usr/local/sbin/runc"

    if test -f /usr/local/sbin/runc; then
        printf "Output: Runc already downloaded and installed in path: $installedToPath\n\n"
    else
        URL_RunC="https://github.com/opencontainers/runc/releases/download/v$Version/runc.$ARCH"
        wget $URL_RunC
        Runc_File="runc.$ARCH"
        install -m 755 runc.$ARCH $installedToPath
        rm $Runc_File
        printf "Output: Success, installed to $installedToPath \n\n"
    fi
}

function download_Runc_Extract_CNI() {
    Version="1.1.1"
    installedPath="/opt/cni/bin"

    if test -f /opt/cni/bin/vlan; then
        printf "Output: CNI already installed, check files to verify: /opt/cni/bin\n"
    else
        CNI_URL="https://github.com/containernetworking/plugins/releases/download/v$Version/cni-plugins-$OS-$ARCH-v$Version.tgz"
        wget $CNI_URL
        CNI_File="cni-plugins-$OS-$ARCH-v$Version.tgz"
        mkdir -p $installedPath
        tar Cxzvf $installedPath $CNI_File
        rm $CNI_File
        printf "Output: Success, installed to $installedPath \n\n"
    fi
}

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
function forwarding_IPV4() {
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter

    # sysctl params required by setup, params persist across reboots
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    # Apply sysctl params without reboot
    sudo sysctl --system
}

function userInput() {
    read USERINPUT

    if [ $USERINPUT == 1 ]; then
        turn_Off_Memory_Swap "sudo sudo swapoff -a" "@reboot sudo swapoff -a" "/var/spool/cron/crontabs/root"
    elif [ $USERINPUT == 2 ]; then
        download_Extract_Run_CRI
    elif [ $USERINPUT == 3 ]; then
        download_Extract_Run_Runc
    elif [ $USERINPUT == 4 ]; then
        download_Runc_Extract_CNI
    elif [ $USERINPUT == 5 ]; then
        forwarding_IPV4

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
2.Download, extract, and run (Containerd)(CRI) version 1.6.4
3.Download, extract, and run (Runc) version 1.1.2
4.Download, extract, and run (CNI plugins) version 1.1.1
5.Forwarding IPv4 and letting iptables see bridged traffic

Input:"
}

showMenu
userInput
