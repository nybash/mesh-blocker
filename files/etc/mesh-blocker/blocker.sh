#!/bin/sh

PID=/var/run/mesh-blocker
LIST=/tmp/mesh_maclist_allowed
DEVICE=wlan0
amount_nodes=
amount_mac=

echo $$ > $PID
logger -t mesh-blocker "Mesh blocker was started with pid: $$"

while sleep 5 
do

	if [ $(iw dev $DEVICE info | grep type | awk '{print $2}') != mesh ]
	then
		logger -t mesh-blocker "Device $DEVICE is not in mesh mode. Sleep 60s."
		sleep 55 
		continue	
	fi


	if [ ! -s "$LIST" ]
	then
		logger -t mesh-blocker "$LIST does not exit or empty. Sleep 30s."
		sleep 25
		continue
	fi

	old_amount_nodes=$amount_nodes
	amount_nodes=$(iw dev $DEVICE station dump | grep "Station " | awk '{print $2}' | md5sum)

	old_amount_mac=$amount_mac
	amount_mac=$(md5sum $LIST)

	if [ "$old_amount_nodes" != "$amount_nodes" ] || [ "$old_amount_mac" != "$amount_mac" ]; then

		for MAC in $(iw dev $DEVICE station dump | grep "Station " | awk '{print $2}'); do
			WHITE=$(grep -i $MAC $LIST)
                            
			if [[ -z $WHITE ]]
			then                                                                                                
				if [[ $(iw dev $DEVICE station get $MAC | grep "mesh plink:" | awk '{print $3}') != BLOCKED ]]
				then                                                    
					iw dev $DEVICE station set $MAC plink_action block
					logger -t mesh-blocker "A station with the mac $MAC has been BLOCKED"
				fi
			elif [[ $(iw dev wlan0 station get $MAC | grep "mesh plink:" | awk '{print $3}') == BLOCKED ]]
			then                                                   
				iw dev $DEVICE station set $MAC plink_action open
				logger -t mesh-blocker "A station with the mac $MAC has been OPENED"
			fi
		done
	fi
done
