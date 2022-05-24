#!/bin/bash

function add_Public_SSH_Key() {
    filePath="$1"
    printf 'Paste your key then press (ctrl + d):\n'
    cat >key.txt
    cp key.txt $filePath
    rm key.txt
    printf "\n\nOutput: Success, the key has been added to that file: $filePath\n\n"
}

# Function to search and change a text in file or add it if not exists, then apply command. SearchingMethod could be '+' or '/'
function change_Pattern_Or_Add_it() {
    filePath="$1" searchForPattern_="$2" updatedPattern_="$3" currentState="$4" command="$5" searchingMethod_="$6"

    if grep -q "^$searchForPattern_" $filePath || grep -q "$updatedPattern_" $filePath; then
        if grep -q "^$searchForPattern_" $filePath; then
            sed -i "s$searchingMethod_$searchForPattern_$searchingMethod_$updatedPattern_$searchingMethod_ g" $filePath
            $command
            printf "Output: Success.. File has been updated: $filePath\n\n "
        else
            printf "Output: $currentState\n\n"
        fi
    else
        echo $updatedPattern_ >>$filePath
        $command
        printf "Output: $updatedPattern_ was not exists, but it has been added to the end of the file: $filePath\n\n"
    fi
}


function Testing(){
    printf "test\n"
}

function userInput() {
    read USERINPUT

    if [ $USERINPUT == 1 ]; then
        Testing
    elif [ $USERINPUT == 2 ]; then
        change_Pattern_Or_Add_it "/etc/systemd/logind.conf" "#HandleLidSwitch=ignore" "HandleLidSwitch=ignore" "Already disabled" "sudo systemctl restart systemd-logind" "+"
    elif [ $USERINPUT == 3 ]; then
        change_Pattern_Or_Add_it "/etc/systemd/logind.conf" "HandleLidSwitch=ignore" "#HandleLidSwitch=ignore" "Already enabled" "sudo systemctl restart systemd-logind" "+"
    elif [ $USERINPUT == 4 ]; then
        currentUser=$(whoami)
        if [ $currentUser == "root" ]; then
            add_Public_SSH_Key "/$currentUser/.ssh/authorized_keys"
        else
            add_Public_SSH_Key "/home/$currentUser/.ssh/authorized_keys"
        fi
    elif [ $USERINPUT == 5 ]; then
        change_Pattern_Or_Add_it "/etc/ssh/sshd_config" "PasswordAuthentication no" "PasswordAuthentication yes" "Already enabled" "sudo service ssh restart" "+"
    elif [ $USERINPUT == 6 ]; then
        change_Pattern_Or_Add_it "/etc/ssh/sshd_config" "PasswordAuthentication yes" "PasswordAuthentication no" "Already disabled" "sudo service ssh restart" "+"
    elif [ $USERINPUT == 7 ]; then
        change_Pattern_Or_Add_it "/etc/ssh/sshd_config" "#PubkeyAcceptedAlgorithms +ssh-rsa" "PubkeyAcceptedAlgorithms +ssh-rsa" "Already added" "sudo service ssh restart" "/"
    elif [ $USERINPUT == 8 ]; then
        change_Pattern_Or_Add_it "/etc/ssh/sshd_config" "PubkeyAcceptedAlgorithms +ssh-rsa" "#PubkeyAcceptedAlgorithms +ssh-rsa" "Already removed" "sudo service ssh restart" "/"

    else
        printf "Output: Invalid character\n\n"
        showMenu
        userInput
    fi
}

function showMenu() {
    printf "
Choose a number:
1.Testing method
2.Disable hibernate when laptop lid down
3.Enable hibernate when laptop lid down
4.Add public SSH key to the current logged in user ($(whoami))
5.Enable password authentication (Login with ssh keys or password)
6.Disable password authentication (Login just with ssh keys if exists)
7.Add acceptedAlgorithms +ssh-rsa for WinSCP
8.Remove acceptedAlgorithms +ssh-rsa key for WinSCP
\n
Input:"
}

showMenu
userInput
