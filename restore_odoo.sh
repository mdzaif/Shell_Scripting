#!/bin/bash
# Description: Odoo database restoration script
# Instruction: make sure you are sudo user or root user
#function
c_dt(){
    date +'%Y_%m_%d_%H_%M_%S'
}

#create log directory and files
if [ ! -d "./logs" ]; then
    mkdir logs
elif [ -f "./logs/resotre_extract.log" ] && [ -f "./logs/restore_bin.log" ] && [ -f "./logs/restore_data.log" ]; then
    rm ./logs/resotre_extract.log ./logs/restore_bin.log ./logs/restore_data.log
else
    echo "Nothing to do!" > /dev/null 2>&1
fi

touch ./logs/resotre_extract.log ./logs/restore_bin.log ./logs/restore_data.log

# extract file
echo "[ $(c_dt) ]:" >> ./logs/restore_extract.log 2>&1
backup_cmp=$(ls -d $(pwd)/odoo_* | grep .tar.gz) # get the tar.gz file
if [ -f $backup_cmp ];then
    tar -xzvf $backup_cmp >> ./logs/restore_extract.log 2>&1
else
    echo "$backup_cmp not existed!" >> ./logs/restore_extract.log 2>&1
fi

#Variables
backup_dir=$(ls -d $(pwd)/odoo_* | grep -v .tar.gz)  # Get first matching directory
backup_file=$(ls "$backup_dir" | grep .backup)  # Get first backup file
bin_backup=$(ls "$backup_dir" | grep .tar.gz)  # Get first tar.gz file
restore_db_name="odoo_db" # adjust manually according your settings
odoo_data_dir="$HOME/.local/share/Odoo"
owner="odoo"
susr=$(whoami)
dblog="postgres"

# PostgreSQL connection parameters
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="$owner"


# Validate backup files exist
if [ ! -f "$backup_dir/$backup_file" ]; then
    echo "[ $(c_dt) ]:" >> ./logs/restore_bin.log 2>&1
    echo "Error: Database backup file not found at $backup_dir/$backup_file" > ./logs/restore_bin.log 2>&1 
    exit 1
fi

if [ ! -f "$backup_dir/$bin_backup" ]; then
    echo "[ $(c_dt) ]:" >> ./logs/restore_bin.log 2>&1
    echo "Error: Binary backup file not found at $backup_dir/$bin_backup" >> ./logs/restore_bin.log 2>&1
    exit 1
fi

# Stop database users service first (uncomment when ready)
# sudo systemctl stop <service>

# Restore binary data
echo "[ $(c_dt) ]:" >>./logs/restore_bin.log 2>&1
echo "Restoring Odoo filestore..." >> ./logs/restore_bin.log 2>&1
rm -rvf "$odoo_data_dir" >> ./logs/restore_bin.log # remove existing data if any
tar -xzvf "$backup_dir/$bin_backup" -C "$(dirname "$odoo_data_dir")" >> ./logs/restore_bin.log 2>&1
echo "Make user permission properly" >> ./logs/restore_bin.log 2>&1
#chown -R $susr:$susr "$odoo_data_dir"  # Set proper permissions

# Restore database
echo "[ $(c_dt) ]:" >> ./logs/restore_data.log 2>&1
echo "Restoring database..." >> ./logs/restore_data.log 2>&1

# First terminate all connections to the target database
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log 2>&1
psql -h $DB_HOST -p $DB_PORT -U $dblog -d postgres -c \
"SELECT pg_terminate_backend(pg_stat_activity.pid) .FROM pg_stat_activity WHERE pg_stat_activity.datname = '$restore_db_name'; DROP DATABASE $restore_db_name;" >>./logs/restore_data.log 2>&1

# Then drop and recreate the database
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log  >>./logs/restore_data.log 2>&1
psql -h $DB_HOST -p $DB_PORT -U $dblog -d postgres -c "DROP DATABASE IF EXISTS $restore_db_name;" >> ./logs/restore_data.log 2>&1
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log  >>./logs/restore_data.log 2>&1
psql -h $DB_HOST -p $DB_PORT -U $dblog -d postgres -c "CREATE DATABASE $restore_db_name WITH OWNER $owner;"  >>./logs/restore_data.log 2>&1

# Restore the backup
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log 2>&1
pg_restore -h $DB_HOST -p $DB_PORT -U $dblog -d $restore_db_name -v "$backup_dir/$backup_file"  >>./logs/restore_data.log 2>&1

# Additional Odoo-specific optimizations
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log  >>./logs/restore_data.log 2>&1
psql -h $DB_HOST -p $DB_PORT -U $dblog -d $restore_db_name -c "VACUUM ANALYZE;"  >>./logs/restore_data.log 2>&1
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log 2>&1
psql -h $DB_HOST -p $DB_PORT -U $dblog -d $restore_db_name -c "UPDATE ir_config_parameter SET value = 'base' WHERE key = 'web.base.url';"  >>./logs/restore_data.log 2>&1

# Restart Odoo service (uncomment when ready)
# sudo systemctl start <odoo>

# final message
if psql -h $DB_HOST -p $DB_PORT -U $dblog -lqt | cut -d \| -f 1 | grep -qw "$restore_db_name"; then
  echo "[ $(c_dt) ]: SUCCESS: Database $restore_db_name restored." >> ./logs/restore_data.log 2>&1
else
  echo "[ $(c_dt) ]: ERROR: Restoration failed!" >> ./logs/restore_data.log 2>&1
  exit 1
fi