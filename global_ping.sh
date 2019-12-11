#!/bin/bash
# ping the world

lookup_host() {
# given a domain, try DNS resolution, if it is found then return the IP and country
	# function to perform a DNS lookup and pretty paint
	local file_name="tld.clean" # name of file

	local domain=$1             # domain comes in as arg

	# parse the result of ipv4 lookup and extract the ip if present
	local ip=$(host -4 $domain|
		grep -v mail|
		grep "has address"|
		awk '{print $4}'|
		grep "[0-9]")

	# if we have an ip, and a country, then return it
	if [ "$ip" ]; then
		local tld=$(echo "$domain"|tr "." " "|awk '{print "."$2}')
		local country_name=$(grep "$tld" ${file_name})
		echo "$ip $country_name"|grep "[a-z]|grep [0-9]"
	fi
}


ping_host() {
# given a domain as an agument, send an icmp echo request packet
	local domain=$1
	# send a single packet with a short timeout
	ping -t2 -c1 "$domain"|grep "64 bytes"
}


domain_permutation() {
# iterate through all of the tlds and prepend"www, nic, and gov"
	local file_name="tld.clean"
	while read -r tld; do
		echo "$tld"|tr -d "\."|awk '{print $1"."$1}'
		echo "$tld"|awk '{print "www"$1}'
		echo "$tld"|awk '{print "nic"$1}'
		echo "$tld"|awk '{print "gov"$1}'
	done < ${file_name}
}


main() {
	# randomly sort the domains
	domain_permutation|sort -R|
	while read -r domain; do 
		# try to resolve domain
		lookup_host "$domain"|while read -r line; do
			# check if an IP address is associated in the result
			local ip=$(echo "$line"|awk '{print $1}')		
			# check the latency of a ping
			local latency=$(ping_host "$ip"|awk '{print $7}'|sed 's/time=//g')
			# if the packet came back, then paint the working result
			if [ "$latency" ]; then
				echo "$latency ms to $line"|grep -v "0.0.0.0"
			fi
		done
	done
}

main
