#!/bin/bash
# Description: Odoo Database Backup Script
# Requirements: PostgreSQL access, tar, basic utilities
# Go to the sudo su - postgres
# type psql
# type  \password postgres
# Enter then type \q for exit; then again type exit 
# Create a file .pgpass inside a directory where you stored the backup_odoo.sh file. i suggest to store the file in your home directory the odoo directory stored.
# Now type chmod 600 .pgpass # if your sudo user add sudo at begin.
# update authentication md5 if not sudo nano /etc/postgresql/<version>/main/pg_hba.conf
# Global configuration

readonly BACKUP_HOME="/home/zaifmahi"
readonly ODOO_DATA_DIR="$BACKUP_HOME/.local/share/Odoo"
readonly DB_USER="postgres"
readonly DB_NAME="odoo_db"
readonly LOG_DIR="$(pwd)/logs"
readonly RETENTION_DAYS=30  # Days to keep old backups

# Initialize variables
timestamp=$(date +'%Y%m%d_%H%M%S')
backup_dir="$BACKUP_HOME/odoo_backup_$timestamp"
backup_archive="$backup_dir.tar.gz"

# Function for consistent logging
log() {
    local log_file="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: $message" >> "$log_file"
}

# Setup logging
setup_logging() {
    mkdir -p "$LOG_DIR"
    exec > >(tee -a "$LOG_DIR/backup_$timestamp.log") 2>&1
    log "$LOG_DIR/backup_$timestamp.log" "Starting Odoo backup process"
}

# Validate PostgreSQL connection
validate_postgres() {
    if ! psql -U "$DB_USER" -lqt >/dev/null; then
        log "$LOG_DIR/backup_$timestamp.log" "ERROR: PostgreSQL connection failed"
        exit 1
    fi
}

# Create binary backup
backup_filestore() {
    log "$LOG_DIR/backup_$timestamp.log" "Starting filestore backup"
    
    if [ ! -d "$ODOO_DATA_DIR" ]; then
        log "$LOG_DIR/backup_$timestamp.log" "ERROR: Odoo data directory not found at $ODOO_DATA_DIR"
        exit 1
    fi

    mkdir -p "$backup_dir"
    tar -czf "$backup_dir/odoo_filestore_$timestamp.tar.gz" \
        --exclude="*/cache/*" \
        -C "$(dirname "$ODOO_DATA_DIR")" \
        "$(basename "$ODOO_DATA_DIR")"
    
    if [ $? -ne 0 ]; then
        log "$LOG_DIR/backup_$timestamp.log" "ERROR: Filestore backup failed"
        exit 1
    fi
}

# Create database backup
backup_database() {
    log "$LOG_DIR/backup_$timestamp.log" "Starting database backup"
    
    pg_dump -U "$DB_USER" -F c -b -v \
        -f "$backup_dir/odoo_db_$timestamp.backup" \
        "$DB_NAME"
    
    if [ $? -ne 0 ]; then
        log "$LOG_DIR/backup_$timestamp.log" "ERROR: Database backup failed"
        exit 1
    fi
}

# Create compressed archive
create_archive() {
    log "$LOG_DIR/backup_$timestamp.log" "Creating final backup archive"
    
    tar -czf "$backup_archive" -C "$BACKUP_HOME" "$(basename "$backup_dir")"
    
    if [ ! -f "$backup_archive" ]; then
        log "$LOG_DIR/backup_$timestamp.log" "ERROR: Archive creation failed"
        exit 1
    fi

    # Set secure permissions
    chmod 600 "$backup_archive"
}

# Cleanup old backups
cleanup_backups() {
    log "$LOG_DIR/backup_$timestamp.log" "Cleaning up backups older than $RETENTION_DAYS days"
    find "$BACKUP_HOME" -name "odoo_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
}

# verify backup
verify_backup() {
    local verify_log="$LOG_DIR/verify_$timestamp.log"
    pg_restore -l "$backup_dir/odoo_db_$timestamp.backup" > "$verify_log" 2>&1
    if [ $? -ne 0 ]; then
        log "$LOG_DIR/backup_$timestamp.log" "ERROR: Database backup verification failed"
        exit 1
    fi
}

# Main execution
main() {
    setup_logging
    validate_postgres
    backup_filestore
    backup_database
    create_archive
    verify_backup
    # Verify backup integrity
    if tar -tzf "$backup_archive" >/dev/null 2>&1; then
        log "$LOG_DIR/backup_$timestamp.log" "Backup completed successfully: $backup_archive"
        
        # Optional: Add upload command here
        # upload_backup "$backup_archive"
        
        # Cleanup temporary files
        rm -rf "$backup_dir"
        cleanup_backups
    else
        log "$LOG_DIR/backup_$timestamp.log" "ERROR: Backup verification failed"
        exit 1
    fi
}

main
