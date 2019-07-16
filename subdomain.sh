#!/bin/bash

amass()
{
	echo "Amass scan on domain $1"
	sudo docker run amass enum --passive -d $1
}
fdns()
{
	echo "FDNS scan on domain $1"
	dom=".$1"
	zcat /root/common_files/fdns/record_a.gz | grep -F $dom\" | jq -r .name | grep "$dom$" | sort | uniq
}
commonspeak2()
{
	echo "Commonspeak2 scan on domain $1"
	while read -r subdomain; do echo "$subdomain.$1"; done < /root/common_files/commonspeak2_subdomains.txt
}
massdns()
{
	echo "Massdns on all_domains_now"
	#now=$(date +"%Y_%m_%d")
	now=$(date +"%Y_%m")
	if [ $(wc -l $1/all_domains_$now) -gt 0 ]
	then
		docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_ipv4.txt -w /subdomains/mass_dns_results.txt -t A /subdomains/all_domains_$now -o S --flush -s 15000 --verify-ip
		cat $1/mass_dns_results.txt | cut -f1 -d' ' | rev | cut -c 2- | rev > $1/all_domains_$now
		rm -f $1/mass_dns_results.txt
		docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_google_cloudflare.txt -w /subdomains/mass_dns_results.txt -t A /subdomains/all_domains_$now -o S --flush -s 15000 --verify-ip
		cat $1/mass_dns_results.txt | cut -f1 -d' ' | rev | cut -c 2- | rev > $1/all_domains_$now
		rm -f $1/mass_dns_results.txt
		cp $1/all_domains_$now $1/all_domains_no_altdns_$now
	else
		touch $1/all_domains_no_altdns_$now
	fi
}
altdns()
{
	#now=$(date +"%Y_%m_%d")
	now=$(date +"%Y_%m")
	echo "Check list for wildcard"
	for dom in $(cat $1/all_domains_$now)
	do
		if [[ "$(dig @1.1.1.1 {test321123,testingforwildcard,plsdontgimmearesult}.$dom A,CNAME +short | wc -l)" -gt "1" ]]; 
		then
			echo "Wildcard in $dom"
		else
			echo "No wildcard in $dom"
			echo $dom >> $1/altdns_$now
		fi
	done
	echo "Altdns on all_domains_now"
	
	docker run -t -v $1:/tmp/altdns altdns -i /tmp/altdns/altdns_$now  -o /tmp/altdns/altdns_results_$now -w /altdns/words.txt # -r -s /tmp/altdns/results_output.txt
	rm -f $1/altdns_$now
}
massdns_post_altdns()
{
	echo "Massdns on altdns"
	now=$(date +"%Y_%m")
	if [ $(wc -l $1/altdns_results_$now) -gt 0 ]
	then
		docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_ipv4.txt -w /subdomains/semifinal_results.txt -t A /subdomains/altdns_results_$now -o S --flush -s 15000 --verify-ip
		rm -f $1/altdns_results_$now
		rm -f $1/all_domains_$now
		cat $1/semifinal_results.txt | cut -f1 -d' ' | rev | cut -c 2- | rev > $1/all_domains_$now
		rm -f $1/semifinal_results.txt
		docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_google_cloudflare.txt -w /subdomains/final_results.txt -t A /subdomains/all_domains_$now -o S --flush -s 15000 --verify-ip
	else
		touch $1/final_results.txt
	fi
	rm -f $1/all_domains_$now
	cat $1/final_results.txt | cut -f1 -d' ' | rev | cut -c 2- | rev > $1/all_domains_$now
	rm -f $1/final_results.txt
	mv $1/all_domains_$now $1/all_domains_tmp_$now
	cat $1/all_domains_no_altdns_$now >> $1/all_domains_$now
	cat $1/all_domains_tmp_$now >> $1/all_domains_$now
	rm -f $1/all_domains_no_altdns_$now
	rm -f $1/all_domains_tmp_$now
	mv $1/all_domains_$now $1/all_domains_tmp_$now
	cat $1/all_domains_tmp_$now | uniq > $1/all_domains_$now
	rm -f $1/all_domains_tmp_$now
}

log()
{
	dt=$(date '+%d/%m/%Y %H:%M:%S');
	echo "$dt $1" >> $2
}

PROJECT_DIR="/root/projects"

project_list=$(ls $PROJECT_DIR)
#now=$(date +"%Y_%m_%d")
now=$(date +"%Y_%m")

for project in $project_list
do
	#Subdomain enumeration
	domains=$(cat "$PROJECT_DIR/$project/Description" | grep SUBDOMAIN | cut -f2 -d'=')
	domain_list=$(echo $domains | tr " " "\n")
	
	status=$(cat $PROJECT_DIR/$project/subdomains/status)
	
	if [[ $status = 0 ]]
	then
		for domain in $domain_list
		do
			#Insert current domain in all_domains_done
			echo "$dom" >> "$PROJECT_DIR/$project/subdomains/all_domains_done_$now"
			
			#If domain has wildcard do nothing
			if [[ "$(dig @1.1.1.1 {test321123,testingforwildcard,plsdontgimmearesult}.$domain A,CNAME +short | wc -l)" -gt "1" ]]; 
			then
				:
			else
				log "FDNS start on $domain" "$PROJECT_DIR/$project/logs/log"
				fdns $domain | grep -v "FDNS scan on"  >> "$PROJECT_DIR/$project/subdomains/fdns_$now"
				log "FDNS finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				log "Amass start on $domain" "$PROJECT_DIR/$project/logs/log"
				amass $domain | grep -v "Amass scan on domain" | grep -v "OWASP Amass" | grep -v "names discovered" >> "$PROJECT_DIR/$project/subdomains/amass_$now"
				log "Amass finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				log "Commonspeak2 start on $domain" "$PROJECT_DIR/$project/logs/log"
				commonspeak2 $domain | grep -v "scan on domain" >> "$PROJECT_DIR/$project/subdomains/commonspeak2_$now"
				log "Commonspeak2 finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				cat "$PROJECT_DIR/$project/subdomains/fdns_$now" > "$PROJECT_DIR/$project/subdomains/all_domains_$now"
				cat "$PROJECT_DIR/$project/subdomains/amass_$now" >> "$PROJECT_DIR/$project/subdomains/all_domains_$now"
				cat "$PROJECT_DIR/$project/subdomains/commonspeak2_$now" >> "$PROJECT_DIR/$project/subdomains/all_domains_$now"
				rm -f "$PROJECT_DIR/$project/subdomains/fdns_$now"
				rm -f "$PROJECT_DIR/$project/subdomains/amass_$now"
				rm -f "$PROJECT_DIR/$project/subdomains/commonspeak2_$now"
				
				log "Massdns start on $domain" "$PROJECT_DIR/$project/logs/log"
				massdns "$PROJECT_DIR/$project/subdomains"
				log "Massdns finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				log "Altdns start on $domain" "$PROJECT_DIR/$project/logs/log"
				altdns "$PROJECT_DIR/$project/subdomains"
				log "Altdns finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				log "Massdns_post_altdns start on $domain" "$PROJECT_DIR/$project/logs/log"
				massdns_post_altdns "$PROJECT_DIR/$project/subdomains"
				log "Massdns_post_altdns finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				cat "$PROJECT_DIR/$project/subdomains/all_domains_$now" >> "$PROJECT_DIR/$project/subdomains/all_domains_done_$now"
				
				echo $domain >> "$PROJECT_DIR/$project/subdomains/all_domains_done_$now"
				
				log "Subdomain $domain scan finished" "$PROJECT_DIR/$project/logs/log"
			fi
		done
	fi
	dt=$(date '+%d/%m/%Y %H:%M:%S');
	echo "1" > $PROJECT_DIR/$project/subdomains/status
	log "Subdomain scan finished on project $project" "$PROJECT_DIR/$project/logs/log"
done
mv "$PROJECT_DIR/$project/subdomains/all_domains_done_$now" "$PROJECT_DIR/$project/subdomains/all_domains_$now"