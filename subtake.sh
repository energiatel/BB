#!/bin/bash

subjack()
{
	now=$(date +"%Y_%m_%d")
	docker run -v $1:/data subjack -v -w /data/$2 -t 100 -timeout 30 -a -m -ssl -o /data/results_subjack_ssl.txt
	docker run -v $1:/data subjack -v -w /data/$2 -t 100 -timeout 30 -a -m -o /data/results_subjack_nossl.txt
}

log()
{
	dt=$(date '+%d/%m/%Y %H:%M:%S');
	echo "$dt $1" >> $2
}

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
			subjack $path $domain_list
			
			log "Subjack executed on domain $(echo $domain_list_cleaned | cut -f6 -d'/')" "$(echo $domain_list_cleaned | cut -f1-4 -d'/')/logs/log"
		done 
	done
done