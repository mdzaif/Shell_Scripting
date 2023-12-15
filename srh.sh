#!/bin/bash

## Written by Md. Zaif Imam Mahi
## Last Modified: Dec 15, 2023
## Description: find the file from system

## Colors
yl='\e[33m'
bl='\e[34m'
n='\e[0m'

usr=$(whoami)
count=0

printf "Search Result\n"
echo -------------------------
read -p "Enter the file name: " nf

while IFS= read -r -d '' i
do
    if [ -f "$i" ]; then
        printf "${yl}$i : it's a regular file ${n}\n"
        count=$((count + 1))
    fi

    if [ -d "$i" ]; then
        printf "${bl}$i : it's a directory ${n}\n"
        count=$((count + 1))
    fi
done < <(find /home/$usr/ -name "$nf" -print0)

echo -------------------------
printf "Total search result: $count\n"
