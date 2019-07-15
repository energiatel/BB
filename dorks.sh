#!/bin/bash

google_dorks_file_containing_juicy_info()
{
	while read dork;
	do
		echo "https://www.google.com/search?q=site:$1 $dork"
	done < /root/common_files/dorks/file_containing_juicy_info
}

google_dorks_open_redirects()
{
	echo "Google dorks for open redirects on $1"
	echo "Usage: ./$0 google_dorks_open_redirects domain.com"
	echo "https://www.google.com/search?q=site:http://docs.google.com docs.google.com $1"
}

shodan()
{
	echo "shodan"
}

github()
{
	echo "github"
	#docker run -e GH_USER='energiatel@gmail.com' -e GH_PWD='fifa99FIFA))' -e GH_TOKEN='a8c06aab5392e76f557e85878be44d54be82d432' githubdorks2 -u myetherwallet
}

pastebin()
{
	echo "pastebin"
}

trello()
{
	echo "trello"
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
		dork_dir=$PROJECT_DIR/$project/dorks
		mkdir -p $dork_dir
		echo $domain
		
		echo "https://www.google.com" > $dork_dir/hosts
		google_dorks_file_containing_juicy_info $domain >> $dork_dir/paths
		sed -i -e 's/ /%20/g' $dork_dir/paths
		sort -u $dork_dir/paths > $dork_dir/dorks
	done
done