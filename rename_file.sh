#!/bin/bash
## Description: only for sequenctial file


read -p "Enter the starting range: " rn1
read -p "Enter the ending range: " rn2

for i in $(eval echo {$rn1..$rn2})
do
    mv
done
