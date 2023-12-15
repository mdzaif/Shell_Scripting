#!/bin/bash

## Written by Md. Zaif Imam Mahi
## Last Modified: Dec 15, 2023
## Description: find the file from system

## Colors
yl='\e[33m'
bl='\e[34m'
n="\e[0m"

usr=$(whoami)
count=0

printf "Search Result"
printf "\n-------------------------\n"
for i in $(find /home/$usr/* -name $1)
do
    if [ -f $i ]
        then
            printf "${yl}$i : it's a regular file ${n}\n"
    elif [ -d $i ]
        then
            printf "${bl}$i : it's a directory ${n}\n"
    fi

    count=$((count + 1))
done

printf "\n-------------------------\n"
printf "Total search result: $count\n"
