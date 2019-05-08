#!/bin/bash
# ping the world

lookup_host() {
	# function to perform a DNS lookup and pretty paint
	local file_name="tld.clean" # name of file
	local domain=$1             # domain comes in as arg
	local ip=$(host -4 $domain|grep -v mail|grep "has address"|awk {'print $4'}|grep "[0-9]")

	if [ "$ip" ]; then
		tld=$(echo $domain|tr "." " "|awk {'print "."$2'})
		country_name=$(grep $tld ${file_name})
		echo "$ip $country_name"|grep [a-z]|grep [0-9]
	fi
}


ping_host() {
	local domain=$1
	ping -t1 -c1 $domain|grep "64 bytes"
}


domain_permutation() {
	local file_name="tld.clean"
	while read tld; do
		echo $tld|tr -d "\."|awk {'print $1"."$1'}
		echo $tld|awk {'print "www"$1'}
		echo $tld|awk {'print "nic"$1'}
		echo $tld|awk {'print "gov"$1'}
	done < ${file_name}
}


main() {
	domain_permutation|sort -R|
	while read domain; do 
		lookup_host $domain|while read line; do
			local ip=$(echo $line|awk {'print $1'})		
			latency=$(ping_host $ip|awk {'print $7'}|sed 's/time=//g')
			if [ "$latency" ]; then
				echo "$latency ms to $line"
			fi
		done
	done
}

main
