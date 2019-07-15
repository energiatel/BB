#!/bin/bash

meg()
{
	docker run -v $1:/data/ meg --verbose -s 200 /data/paths /data/hosts
}

PROJECT_DIR="/root/projects"

project_list=$(ls $PROJECT_DIR)
now=$(date +"%Y_%m")

MINWAIT=30
MAXWAIT=180

for project in $project_list
do
	for domain in $(ls "$PROJECT_DIR/$project/subdomains" | grep -v status)
	do
		for subdomain_list in $(ls "$PROJECT_DIR/$project/subdomains/$domain" | grep all_domains_clean)
		do
			#echo "$PROJECT_DIR/$project/subdomains/$domain/$subdomain_list"
			for subdomain in $(cat "$PROJECT_DIR/$project/subdomains/$domain/$subdomain_list")
			do
				echo $subdomain
				if host "$subdomain" > /dev/null
				then
					echo "$subdomain" >> "$PROJECT_DIR/$project/subdomains/$domain/live"
				fi
			done			
			for live_host in $(cat "$PROJECT_DIR/$project/subdomains/$domain/live")
			do
				echo "http://$live_host" >> "$PROJECT_DIR/$project/subdomains/$domain/hosts"
				echo "https://$live_host" >> "$PROJECT_DIR/$project/subdomains/$domain/hosts"
			done
			echo '/' > "$PROJECT_DIR/$project/subdomains/$domain/paths"
			meg "$PROJECT_DIR/$project/subdomains/$domain/"
			
			rm -f "$PROJECT_DIR/$project/subdomains/$domain/live"
			rm -f "$PROJECT_DIR/$project/subdomains/$domain/hosts"
			rm -f "$PROJECT_DIR/$project/subdomains/$domain/paths"
			
			if [ -s "$PROJECT_DIR/$project/subdomains/$domain/out/index" ]
			then
				for live_host in $(cat "$PROJECT_DIR/$project/subdomains/$domain/out/index" | awk '{ print $2 }')
				do
					echo $live_host > "$PROJECT_DIR/$project/subdomains/$domain/live"
				done
			fi
			rm -rf "$PROJECT_DIR/$project/subdomains/$domain/out"
		done
	done
done