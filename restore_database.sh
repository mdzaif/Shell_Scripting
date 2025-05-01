#!/bin/bash


#function
c_dt(){
return $(date +'%Y_%m_%d::%H:%M:%S');
}


# Variables
backup_dir=$(ls -d /home/zaifmahi/github/Shell_Scripting/odoo_* | head -1)  # Get first matching directory
backup_file=$(ls "$backup_dir"/*.backup | head -1)  # Get first backup file
bin_backup=$(ls "$backup_dir"/*.tar.gz | head -1)  # Get first tar.gz file
restore_db_name="odoo_db"
odoo_data_dir="$HOME/.local/share/Odoo"
owner="odoo"
susr=$(whoami)
dblog="postgres"

# PostgreSQL connection parameters
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="$owner"



#create log directory and files
mkdir logs/
touch ./logs/restore_bin.log ./logs/restore_data.log

# Validate backup files exist
if [ ! -f "$backup_file" ]; then
    echo "[ $(c_dt) ]:" >> ./logs/restore_bin.log
    echo "Error: Database backup file not found at $backup_file" > ./logs/restore_bin.log 
    exit 1
fi

if [ ! -f "$bin_backup" ]; then
    echo "[ $(c_dt) ]:" >> ./logs/restore_bin.log
    echo "Error: Binary backup file not found at $bin_backup" >> ./logs/restore_bin.log
    exit 1
fi

# Stop database users service first (uncomment when ready)
# sudo systemctl stop <service>

# Restore binary data
echo "[ $(c_dt) ]:" >>./logs/restore_bin.log
echo "Restoring Odoo filestore..." >> ./logs/restore_bin.log
rm -rvf "$odoo_data_dir" >> ./logs/restore_bin.log # remove existing data if any
tar -xzvf "$bin_backup" -C "$(dirname "$odoo_data_dir")" >> ./logs/restore_bin.log
echo "Make user permission properly" >> ./logs/restore_bin.log
chown -R $susr:$susr "$odoo_data_dir"  # Set proper permissions

# Restore database
echo "[ $(c_dt) ]:" >> ./logs/restore_data.log
echo "Restoring database..." >> ./logs/restore_data.log

# First terminate all connections to the target database
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log
psql -h $DB_HOST -p $DB_PORT -U $dblog -d postgres -c \
"SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$restore_db_name';" >>./logs/restore_data.log

# Then drop and recreate the database
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log  >>./logs/restore_data.log
psql -h $DB_HOST -p $DB_PORT -U $dblog -d postgres -c "DROP DATABASE IF EXISTS $restore_db_name;" >> ./logs/restore_data. 
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log  >>./logs/restore_data.log
psql -h $DB_HOST -p $DB_PORT -U $dblog -d postgres -c "CREATE DATABASE $restore_db_name WITH OWNER $owner;"  >>./logs/restore_data.log

# Restore the backup
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log
pg_restore -h $DB_HOST -p $DB_PORT -U $dblog -d $restore_db_name -v "$backup_file"  >>./logs/restore_data.log

# Additional Odoo-specific optimizations
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log  >>./logs/restore_data.log
psql -h $DB_HOST -p $DB_PORT -U $dblog -d $restore_db_name -c "VACUUM ANALYZE;"  >>./logs/restore_data.log
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log
psql -h $DB_HOST -p $DB_PORT -U $dblog -d $restore_db_name -c "UPDATE ir_config_parameter SET value = 'base' WHERE key = 'web.base.url';"  >>./logs/restore_data.log

# Restart Odoo service (uncomment when ready)
# sudo systemctl start odoo
echo "[ $(c_dt) ]: " >> ./logs/restore_data.log 
echo "Restoration complete. Database name: $restore_db_name"  >>./logs/restore_data.log
