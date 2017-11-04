#!/bin/bash

COMMAND=$1
ROTATION_PERIOD=$2

if [ -z COMMAND ];
	then
		echo "Usage of $1: Please Define COMMAND { delete or backup } to run "
		exit 1
fi

function backup_ebs () {
	for volume in $(aws ec2 describe-volumes | jq .Volumes[].VolumeId | sed 's/\"//g' )
	do 
		echo Creating snapshot for $volume $(aws ec2 create-snapshot --volume-id $volume --description "backup-script" )
	done
}

function delete_snapshot () {

	if  [ -z $1 ] || ! [[ "$1" =~ ^[0-9]+$ ]];
	then
		echo "Please enter the age of backups you want to delete and it must be integer"
		exit 1
	else
		for snapshot in $(aws ec2 describe-snapshots --filters Name=description,Values=backup-script | jq .Snapshots[].SnapshotId | sed 's/\"//g')
		do
			SNAPSHOT_DATE=$(aws ec2 describe-snapshots --filters Name=snapshot-id,Values=$snapshot | jq .Snapshots[].StartTime | cut -d T -f1 | sed 's/\"//g' )
			START_DATE=$(date +"%Y-%m-%d")
			INTERVAL=$(datediff $SNAPSHOT_DATE $START_DATE)
			if (($INTERVAL > $ROTATION_PERIOD));
				then
					echo "deleting snapshot $snapshot "
					aws ec2 delete-snapshot --snapshot-id $snapshot
			fi
		done
	fi
}

case $COMMAND in
	backup )
			backup_ebs
		;;
	delete )
			delete_snapshot $ROTATION_PERIOD
		;;
	* )
			echo "Following command is not VALID. Please use backup or delete command only"
		;;
esac
