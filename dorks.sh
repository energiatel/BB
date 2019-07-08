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

google_dorks_file_containing_juicy_info $1