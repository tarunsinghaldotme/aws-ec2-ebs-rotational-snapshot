#!`which bash`

COMMAND=$1
ROTATION_PERIOD=$2

if [ -z COMMAND ];
	then
		echo "Usage of $1: Please Define COMMAND { delete or backup } to run "
		exit 1
fi

if [ $COMMAND = "delete"] && [ -z ROTATION_PERIOD ];
	then
		echo "Please enter the age of backups you want to delete "
		exit 1
fi

function backup_ebs () {
	for volume in $(aws ec2 describe-volumes | jq .Volumes[].VolumeId | sed 's/\"//g' )
	do 
		echo Creating snapshot for $volume $(aws ec2 create-snapshot --volume-id $volume --description "backup-script" )
	done
}

function delete_snapshot () {
	for snapshot in $(aws ec2 describe-snapshots --filters Name=description,Values=backup-script | jq .Snapshots[].SnapshotId | sed 's/\"//g')
	do
		SNAPSHOT_DATE=$(aws ec2 describe-snapshots --filters Name=snapshot-id,Values=$snapshot | jq .Snapshots[].StartTime | cut -d T -f1 | sed 's/\"//g' )
		START_DATE=$(date +%s)
		END_DATE=$(date - $SNAPSHOT_DATE +%s)
		INTERVAL=$[(START_DATE - END_DATE) / 60*60*24 ]
		if ((INTERVAL > $ROTATION_PERIOD));
			then
				echo "deleting snapshot $snapshot "
				aws ec2 delete-snapshot --snapshot-id $snapshot
		fi
	done
}

case $COMMAND in
	backup )
			backup_ebs
		;;
	delete )
			delete-snapshot
		;;
	* )
			echo "Following command is not VALID. Please use backup or delete command only"
		;;
esac
