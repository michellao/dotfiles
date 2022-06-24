#!/bin/bash

function isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
	fi
}

function createAP {
	create_ap --config /etc/create_ap.conf
	sleep 5
	create_ap_PID=$(ls /tmp | grep -E "create_ap.[0-9]+.lock" | cut -d . -f 2)
	echo "Create Wi-Fi ${create_ap_PID}"
}

function verifyPID() {
	create_ap_PID=$(ls /tmp | grep -E "create_ap.[0-9]+.lock" | cut -d . -f 2)
	if [ "$(create_ap --list-running | wc -l)" -gt 0 ]; then
		echo "Wi-Fi is already active ${create_ap_PID}"
		exit 1
	else
		createAP
	fi
}


isRoot

echo "Accept forward packet"
nft chain inet filter forward '{ policy accept ; }';
verifyPID

exit 0
