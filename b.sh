#!/bin/bash

#TODO
# - Implementare altdns come in subdomain.sh originale

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
	now=$(date +"%Y_%m")
	all_domains_clean_size=$(wc -l "$1/all_domains_clean_$now" | cut -f1 -d' ')
	if [ $all_domains_clean_size -gt 0 ]
	then
		docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_ipv4.txt -w /subdomains/mass_dns_results.txt -t A /subdomains/all_domains_clean_$now -o S --flush -s 15000 --verify-ip
		cat $1/mass_dns_results.txt | cut -f1 -d' ' | rev | cut -c 2- | rev > $1/all_domains_clean_$now
		rm -f $1/mass_dns_results.txt
		all_domains_now_clean_size=$(wc -l "$1/all_domains_clean_$now" | cut -f1 -d' ')
		if [ $all_domains_now_clean_size -gt 0 ]
		then
			docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_google_cloudflare.txt -w /subdomains/mass_dns_results.txt -t A /subdomains/all_domains_clean_$now -o S --flush -s 15000 --verify-ip
			cat $1/mass_dns_results.txt | cut -f1 -d' ' | rev | cut -c 2- | rev > $1/all_domains_$now
			rm -f $1/mass_dns_results.txt
			cp $1/all_domains_$now $1/all_domains_clean_$now
			rm -f $1/all_domains_$now
		else
			echo "Empty $1/all_domains_clean_$now"
		fi
	else
		echo "Empty $1/all_domains_no_altdns_$now"
	fi
}
altdns()
{
	echo "Altdns on all_domains_clean_$now"
	now=$(date +"%Y_%m")
	cp $1/all_domains_clean_$now $1/altdns_$now
	
	docker run -t -v $1:/tmp/altdns altdns -i /tmp/altdns/altdns_$now  -o /tmp/altdns/altdns_results_$now -w /altdns/words.txt # -r -s /tmp/altdns/results_output.txt
	rm -f $1/altdns_$now
}
massdns_post_altdns()
{
	echo "--- Massdns on altdns ---"
	now=$(date +"%Y_%m")
	altdns_results_size=$(wc -l "$1/altdns_results_$now" | cut -f1 -d' ')
	if [ $altdns_results_size -gt 0 ]
	then
		docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_ipv4.txt -w /subdomains/altdns_semifinal_results.txt -t A /subdomains/altdns_results_$now -o S --flush -s 15000 --verify-ip
		rm -f $1/altdns_results_$now
		cat $1/altdns_semifinal_results.txt | cut -f1 -d' ' | rev | cut -c 2- | rev > $1/altdns_results_$now
		rm -f $1/altdns_semifinal_results.txt
		altdns_results_size=$(wc -l "$1/altdns_results_$now" | cut -f1 -d' ')
		if [ $altdns_results_size -gt 0 ]
		then
			docker run -ti --rm -v /root/common_files:/common_files -v $1:/subdomains massdns -r /common_files/nameservers_google_cloudflare.txt -w /subdomains/altdns_final_results.txt -t A /subdomains/altdns_results_$now -o S --flush -s 15000 --verify-ip
			rm -f $1/altdns_results_$now
			mv $1/altdns_final_results.txt $1/altdns_results_$now
		else
			echo "Empty $1/altdns_results_$now"
		fi
	else
		echo "Empty $1/altdns_results_$now"
	fi
}

log()
{
	dt=$(date '+%d/%m/%Y %H:%M:%S');
	echo "[$dt] $1" >> "$2"
	echo "[$dt] $1"
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
		echo "$domain"
			log "Start subdomain for domain $domain" "$PROJECT_DIR/$project/logs/log"
			mkdir "$PROJECT_DIR/$project/subdomains/$domain" 2>/dev/null
			log "$PROJECT_DIR/$project/subdomains/$domain directory created" "$PROJECT_DIR/$project/logs/log"
			
			#Check for wildcard on domain
			if [[ "$(dig @1.1.1.1 {test321123,testingforwildcard,plsdontgimmearesult}.$domain A,CNAME +short | wc -l)" -gt "1" ]];
			then
				log "Domain $domain has wildcard" "$PROJECT_DIR/$project/logs/log"
			else
				log "FDNS start on $domain" "$PROJECT_DIR/$project/logs/log"
				fdns $domain | grep -v "FDNS scan on"  >> "$PROJECT_DIR/$project/subdomains/$domain/fdns_$now"
				results_number=$(wc -l $PROJECT_DIR/$project/subdomains/$domain/fdns_$now | cut -f1 -d' ')
				log "FDNS finished on $domain with $results_number results" "$PROJECT_DIR/$project/logs/log"
				cat "$PROJECT_DIR/$project/subdomains/$domain/fdns_$now" >> "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now" #&& rm -f "$PROJECT_DIR/$project/subdomains/$domain/fdns_$now"
				
				log "Amass start on $domain" "$PROJECT_DIR/$project/logs/log"
				amass $domain | grep -v "Amass scan on domain" | grep -v "OWASP Amass" | grep -v "names discovered" >> "$PROJECT_DIR/$project/subdomains/$domain/amass_$now"
				results_number=$(wc -l $PROJECT_DIR/$project/subdomains/$domain/amass_$now | cut -f1 -d' ')
				log "Amass finished on $domain with $results_number results" "$PROJECT_DIR/$project/logs/log"
				cat "$PROJECT_DIR/$project/subdomains/$domain/amass_$now" >> "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now" #&& rm -f "$PROJECT_DIR/$project/subdomains/$domain/amass_$now"

				log "Commonspeak2 start on $domain" "$PROJECT_DIR/$project/logs/log"
				commonspeak2 $domain | grep -v "scan on domain" >> "$PROJECT_DIR/$project/subdomains/$domain/commonspeak2_$now"
				results_number=$(wc -l $PROJECT_DIR/$project/subdomains/$domain/commonspeak2_$now | cut -f1 -d' ')
				log "Commonspeak2 finished on $domain with $results_number results" "$PROJECT_DIR/$project/logs/log"
				cat "$PROJECT_DIR/$project/subdomains/$domain/commonspeak2_$now" >> "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now" #&& rm -f "$PROJECT_DIR/$project/subdomains/$domain/commonspeak2_$now"

				log "Massdns start on $domain" "$PROJECT_DIR/$project/logs/log"
				massdns "$PROJECT_DIR/$project/subdomains/$domain/"
				results_number=$(wc -l $PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now | cut -f1 -d' ')
				log "Massdns finished on $domain with $results_number results" "$PROJECT_DIR/$project/logs/log"
				
				log "Altdns start on $domain" "$PROJECT_DIR/$project/logs/log"
				altdns "$PROJECT_DIR/$project/subdomains/$domain/"
				log "Altdns finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				log "Massdns_post_altdns start on $domain" "$PROJECT_DIR/$project/logs/log"
				massdns_post_altdns "$PROJECT_DIR/$project/subdomains/$domain/"
				log "Massdns_post_altdns finished on $domain" "$PROJECT_DIR/$project/logs/log"
				
				cat "$PROJECT_DIR/$project/subdomains/$domain/altdns_results_$now" >> "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now"
				
				sort "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now" | uniq -u > "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now_tmp"
				rm -f "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now"
				mv "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now_tmp" "$PROJECT_DIR/$project/subdomains/$domain/all_domains_clean_$now"
			fi
			
			log "Finished subdomain for domain $domain" "$PROJECT_DIR/$project/logs/log"
			
		done
	fi
	echo "1" > $PROJECT_DIR/$project/subdomains/status
done
