#!/bin/bash

google_dorks
{
	echo "Google dorks for $1"
	echo "https://www.google.com/search?q=site:http://docs.google.com docs.google.com $1"
}

shodan
{
}

github
{
	#usare https://github.com/techgaun/github-dorks
	#modificare https://github.com/energiatel/altdns/blob/master/Dockerfile per dockerizzare
}

pastebin
{
}

trello
{
}