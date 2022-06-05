#!/bin/bash

function install_docker() {
 sudo curl -fsSL https://get.docker.com -o get-docker.sh
 sudo sh get-docker.sh
 sudo systemctl start docker
 sudo rm get-docker.sh
}

function remove_docker() {
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce  
}

function userInput() {
    read USERINPUT

    if [ $USERINPUT == 1 ]; then
        install_docker
    elif [ $USERINPUT == 2 ]; then
        remove_docker

    else
        printf "Output: Invalid character\n\n"
        showMenu
        userInput
    fi
}

function showMenu() {
    printf "
Choose a number:
1.Install docker
2.Remove docker
Input:"
}

showMenu
userInput