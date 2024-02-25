#!/usr/bin/env bash

function isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
	fi
}

function nftRule() {
	echo "Nftables update"
	nft add rule inet filter udp_chain udp dport { 5353, 67 } accept
	nft add rule inet filter forward iif "enp3s0f4u1" oif "ap0" accept
	nft add rule inet filter forward iif "ap0" accept
	touch /tmp/nftRule
}

function wireguardActive {
	existWireGuard="$(ip l | grep wg0)"
	if [ -n "$existWireGuard" ]; then
		nft add rule inet filter forward iif "wg0" oif "ap0" accept
	fi
}

function nftRuleAfterLaunch() {
	if [ -e /tmp/nftRule ]; then
		nft add rule inet filter forward iif "enp3s0f4u1" oif "ap0" accept
		nft add rule inet filter forward iif "ap0" accept
	fi
}

function createAP {
	create_ap --config /etc/create_ap.conf
	sleep 3
	if [ ! -e /tmp/nftRule ]; then
		nftRule
	else
		nftRuleAfterLaunch
	fi
	wireguardActive
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
verifyPID

exit 0
