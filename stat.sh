#!/bin/bash

PROJECT_DIR="/root/projects"

project_list=$(ls $PROJECT_DIR)
now=$(date +"%Y_%m")

for project in $project_list
do
	for domain in $(ls "$PROJECT_DIR/$project/subdomains" | grep -v status)
	do
		domain_list=$(ls $PROJECT_DIR/$project/subdomains/$domain | grep "all_domains_clean*")
		for domain_list_cleaned in $(echo "$PROJECT_DIR/$project/subdomains/$domain/$domain_list" | grep "all_domains_clean*")
		do
			path=$(echo $domain_list_cleaned | cut -f1-6 -d'/')
			
			#subjack $path $domain_list			
			#log "Subjack executed on domain $(echo $domain_list_cleaned | cut -f6 -d'/')" "$(echo $domain_list_cleaned | cut -f1-4 -d'/')/logs/log"

			
			if [ -s "$path/results_subjack_ssl.txt" ]
			then
				cat "$path/results_subjack_ssl.txt" | grep -v '[Not Vulnerable]' | grep -v 'DEAD DOMAIN' > "$PROJECT_DIR/$project/takeover/takeover_results_$now"
			fi
			if [ -s "$path/results_subjack_nossl.txt" ]
			then
				cat "$path/results_subjack_nossl.txt" | grep -v '[Not Vulnerable]' | grep -v 'DEAD DOMAIN' >> "$PROJECT_DIR/$project/takeover/takeover_results_$now"
			fi
		done
	done
	echo '1' > "$PROJECT_DIR/$project/takeover/status"
done



			if [ $1 = 'status' ]
			then
				echo "$PROJECT_DIR/$project/takeover/takeover_results_$now"
				cat "$PROJECT_DIR/$project/takeover/takeover_results_$now"
				echo "$PROJECT_DIR/$project/takeover/takeover_results_$now"
				cat "$PROJECT_DIR/$project/takeover/takeover_results_$now"
			else