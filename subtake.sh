#!/bin/bash

subjack()
{
	now=$(date +"%Y_%m_%d")
	docker run -v $1:/data subjack -v -w /data/subdomains/$2 -t 100 -timeout 30 -o /data/takeover/results_subjack_$now
}

PROJECT_DIR="/root/projects"

project_list=$(ls $PROJECT_DIR)

for project in $project_list
do
	#Subdomain lists
	subdomains=$(ls -larth $PROJECT_DIR/$project/subdomains/ | head -2 | grep -v total | grep -v '\.' | awk '{ print $9 }')
	echo "$PROJECT_DIR/$project/" "$subdomains"
	//subjack "$PROJECT_DIR/$project/$subdomains"
	now=$(date +"%Y_%m_%d")

done