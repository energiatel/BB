#!/bin/bash

takeover()
{
	if [ -s "$1" ]
	then
		echo "$1"
		cat "$1"
		printf "\n"
	fi
}

PROJECT_DIR="/root/projects"

project_list=$(ls $PROJECT_DIR)

for project in $project_list
do
	case $1 in
	'takeover')
		direct="$PROJECT_DIR/$project/takeover/takeover_results*"
		takeover_results=$(ls $direct 2>/dev/null)
		for res in $takeover_results
		do
			takeover $res
		done
		;;
	esac
done