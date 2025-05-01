#!/bin/bash

#function
c_dt(){
date +'%Y_%m_%d::%H:%M:%S'
}


#variables
home="/home/zaifmahi"
dt=$(c_dt)
dirname="odoo_data_backup_"$dt
datafile="odoo_data_file_"$dt
filename="odoo_bin_data_backup_"$dt
bin_dir=$home"/.local/share/"
dbuser="postgres"
dbname="odoo_db"

# Create backup folder

mkdir $dirname

# remove old logs
rm logs/backup_bin.log ./logs/backup_data.log ./logs/backup_upload.log 

# Create log folder and files
if [ ! -d "./logs" ];then
    mkdir logs
fi

touch ./logs/backup_bin.log ./logs/backup_data.log ./logs/backup_upload.log 

# Create binary backup
echo "[ $(c_dt) ]:" >> ./logs/backup_bin.log 2>&1
if [ -d "$bin_dir" ]; then
    tar -czvf "$dirname/$filename.tar.gz" -C "$bin_dir" Odoo >> ./logs/backup_bin.log 2>&1
else
    echo "$bin_dir directory does not exist!" >> ./logs/backup_bin.log 2>&1
fi
# Create database backup
echo "[ $(c_dt) ]:" >> ./logs/backup_data.log 2>&1
pg_dump -U $dbuser  -F c -b -v -f "$dirname/$datafile.backup" "$dbname" >> ./logs/backup_data.log 2>&1

# check thef file in selected directory
echo "[ $(c_dt) ]:"  >> ./logs/backup_data.log 2>&1
ls -l $dirname >> ./logs/backup_data.log 2>&1

# tar compress the directory


# data upload 

