#!/bin/sh

# ================================================================================================ #
# Bash script to dump MySQL's production and development databases, writing over the dev database  #
# ================================================================================================ #

# ================================================================================================ #
#                                                                                                  #
# REQUIRED - connection_settings.json and directory for dumps must exist in specified locations
# jq is needed to parse the connection_settings.json file, dl with 'pkg install jq' -FreshPorts    #
#                                                                                                  #
# ------------------------------------------------------------------------------------------------ #
# IMPORTANT - Database hosts may change over time, please update this script as necessary          #
#	The same will go for the credentials for those databases, update as per needed                 #
#                                                                                                  #
# ================================================================================================ #

# Conditional check to see if connection_settings.json exists
if [ ! -f /usr/local/etc/connection_settings.json ]; then

# In the case it doesn't exist, script echos out saying so and exits script
    echo "/usr/local/etc/connection_settings.json not found."
    exit 1

else
    # Declare variables for host, user, and password for test and live tables

	# Assuming your databases are stored on the same MySQL database server
	dbHost="server.com"

	# Grab and set Developer Database values for connection by using 'jq' to parse /usr/local/etc/connection_settings.json
	devDB=$( cat /usr/local/etc/connection_settings.json | jq -r '.[] | .dbDev.dbname | select(.!=null)' )
	devName=$( cat /usr/local/etc/connection_settings.json | jq -r '.[] | .dbDev.username | select(.!=null)' )
	devPass=$( cat /usr/local/etc/connection_settings.json | jq -r '.[] | .dbDev.PASSWORD | select(.!=null)' )

	# Grab and set Production Database values for connection by using 'jq' to parse /usr/local/etc/connection_settings.json
	prodDB=$( cat /usr/local/etc/connection_settings.json | jq -r '.[] | .dbProd.dbname | select(.!=null)' )
	prodName=$( cat /usr/local/etc/connection_settings.json | jq -r '.[] | .dbProd.username | select(.!=null)' )
    prodPass=$( cat /usr/local/etc/connection_settings.json | jq -r '.[] | .dbProd.PASSWORD | select(.!=null)' )

    # Timestamp
    date=$(date +"%d-%b-%Y")

    # Backup path
    backup_path="/tmp/dumps"

    # ====== Dumps Begins Here ======

    # Default file permissions
    umask 177

    echo "$date:"

    # Development Database dump
   	echo "Dumping development database to $backup_path/dev-DB-backup-$date.sql"
    mysqldump --user=$devName --password=$devPass --host=$dbHost $devDB > $backup_path/dev-DB-backup-$date.sql
    if [ -f $backup_path/dev-DB-backup-$date.sql ]; then
        echo "Development database dump to $backup_path done."
    fi

    # Production Database dump
   	echo "Dumping production database to $backup_path/prod-DB-backup-$date.sql"
   	mysqldump --user=$prodName --password=$prodPass --host=$dbHost $prodDB > $backup_path/prod-DB-backup-$date.sql
    if [ -f $backup_path/prod-DB-backup-$date.sql ]; then
        echo "Production database dump to $backup_path done."
    fi

    # ====== Restore Begins Here ======

    # Restore Production Database dump over Development Database
   	echo "Restoring production database dump over development database."
   	mysql --user=$devName --password=$devPass --host=$dbHost $devDB < $backup_path/prod-DB-backup-$date.sql && echo "Restore complete."

    # ====== File Cleanup ======

    # Delete backups older than 6 days
    find $backup_path/* -name '*.sql' -mtime +6 -exec rm {} \;

fi
