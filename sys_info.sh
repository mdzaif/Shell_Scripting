#!/bin/bash

## Written by Md. Zaif Imam Mahi
## Last Modified: December 7, 2023
## add this command to .bashrc: alias info="curl -s https://raw.githubusercontent.com/mdzaif/Shell_For_Fun/main/sys_info.sh | bash" 


## variables
Scale=2
mt=$(awk -F" " 'NR==1 {print $2}' /proc/meminfo)
mt=$(echo "scale=$Scale; $mt/1024/1024" | bc -l)
pac=$(expr $(dpkg-query -l | wc -l) - 5)
shell=$(echo $SHELL)
os_name=$(grep -w "ID" /etc/os-release | awk -F'=' '{print $2}')

## colors
red="\e[31m"
n="\e[0m"

echo

jp2a https://github.com/mdzaif/image/$os_name.jpg --size=50x25 --colors > /tmp/image_ascii.txt

paste /tmp/image_ascii.txt <(printf "\n${red}$(whoami)${n}@${red}$(hostname) $n\
\n--------------------\n\
${red}User${n}: $(whoami) \n\
${red}Group${n}(${red}s${n}): $(groups)\n\
${red}UID${n}: $UID \n\
${red}GID${n}: $(id <<< whoami | awk -F'groups=' '{print $2}')\n\
${red}Uptime${n}: $(uptime -p | cut -c4-)\n\
${red}OS${n}:  $(awk -F'\"' 'NR==1 {print $2}' /etc/os-release) $(arch)\n\
${red}Shell${n}: $($shell --version | awk 'NR==1 {print}')\n\
${red}Kernel${n}: $(uname -r)\n\
${red}Packages${n}(${red}dpkg${n}): $pac \n\
${red}CPU${n}: $(grep 'model name' /proc/cpuinfo | awk -F': ' 'NR==2 {print $NR}')\n\
${red}Memory${n}: total: $mt GB\n\
${red}GPU${n}: $(lspci -v | grep 'VGA' | awk -F': ' '{print $2}') \n")

rm /tmp/image_ascii.txt

echo
echo

