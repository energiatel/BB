#!/bin/bash

echo "[+] Installazione prerequitisiti"
echo "[+] Update the system"
yum -y update
echo "[+] Installo vim"
yum -y install vim
echo "[+] Installo wget"
yum -y install wget
echo "[+] Installo git"
yum -y install git
echo "[+] Install open-vm-tools"
yum -y install open-vm-tools
echo '[+] Install and config NFS'
#https://www.howtoforge.com/nfs-server-and-client-on-centos-7
yum -y install nfs-utils
mkdir -p /mnt/nfs/var/nfsshare
mount -t nfs 192.168.1.201:/var/nfsshare /mnt/nfs/var/nfsshare/
echo '[+] Imposto la chiave'
mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAqdjbeAkUtorcf7dqo3mC8l+JVCgIZMTX6n32wXrgEDPYs9mzCNBn1IqMIUk71xnosefug/DEcIdG5Mi23E0BeOsaBRsRIZGbgX7gsWppaqtXogwCBw+EWpbQuw0vzxglxjzYgw8SJxLu8APlRfywTlocDCVVNBLRXwYqHPTDGyVGVFxc8lNBXAIH5vLUKA/K/Cz8u3kUyiVdVbiKnj0ed78PIXZG7jrUp7D4MWJyCjAtVXrXspz531CGMh9Il9vQa9KLrLDsOmsKnLWrYQYnN3l9YRRjwI3up8N4QRv3f7Tuwt5sIjMdToqXBsk5fZEJZj2/MTAGD2OV55Zz/E+2yQ== rsa-key-20190609' > ~/.ssh/authorized_keys

#Creo utente user
echo "[+] Create user user for Docker"
useradd user
echo user | passwd user --stdin

#Install docker
echo "[+] Install docker"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
systemctl enable docker
systemctl start docker
rm -f get-docker.sh
sleep 10
usermod -aG docker user

#Installo AMASS
echo "[+] Install AMASS"
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum -y swap git git2u
docker build -t amass https://github.com/OWASP/Amass.git

#Scarico Rapid7 FDNS Sonar
echo "[+] Ricordati di aggiornare i link ai file piu recenti"
echo "[+] Sia per record A che AAAA"
echo "[+] https://opendata.rapid7.com/sonar.fdns_v2/"
echo "[+] Download FDNS files"
mkdir /root/fdns/
#wget https://opendata.rapid7.com/sonar.fdns_v2/2019-05-26-1558831458-fdns_a.json.gz -O /root/fdns/record_a.gz
cp /mnt/nfs/var/nfsshare/record_a.gz /root/fdns/record_a.gz &
#wget https://opendata.rapid7.com/sonar.fdns_v2/2019-05-24-1558737480-fdns_aaaa.json.gz  -O /root/fdns/record_aaaa.gz
cp /mnt/nfs/var/nfsshare/record_aaaa.gz /root/fdns/record_aaaa.gz &

#Scarico JQ
echo "JW Download from https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /root/common_files/jq-linux64
chmod +x /root/common_files/jq-linux64

echo "VERIFICARE SE FUNZIONA QUESTO COMANDO"
ln -s /root/common_files/jq-linux64 /usr/bin/jq

#Scarico la lista commonspeak2
wget https://raw.githubusercontent.com/assetnote/commonspeak2-wordlists/master/subdomains/subdomains.txt -O /root/common_files/commonspeak2_subdomains.txt
sed -i '/^$/d' /root/common_files/commonspeak2_subdomains.txt

#Installo MassDNS
echo "[+] Install MassDNS"
docker build -t "massdns:latest" https://github.com/blechschmidt/massdns.git
#Download nameservers.txt 
echo 'Download nameservers.txt from https://public-dns.info/nameservers.txt'
wget https://public-dns.info/nameservers.txt -O /root/common_files/nameservers.txt
#Pulisco lista nameservers.txt da IPV6
for ip in $(cat /root/common_files/nameservers.txt); do if [[ $ip =~ \.[0-9]+$ ]]; then echo $ip >> /root/common_files/nameservers_ipv4.txt; fi; done;
rm -f /root/common_files/nameservers.txt
#Elimino IP DNS di Google e Cloudflare
grep -v "8\.8\.8\.8" /root/common_files/nameservers_ipv4.txt > /root/common_files/nameservers_ipv4.txt_tmp; mv -f /root/common_files/nameservers_ipv4.txt_tmp /root/common_files/nameservers_ipv4.txt
grep -v "8\.4\.4\.8" /root/common_files/nameservers_ipv4.txt > /root/common_files/nameservers_ipv4.txt_tmp; mv -f /root/common_files/nameservers_ipv4.txt_tmp /root/common_files/nameservers_ipv4.txt
grep -v "1\.1\.1\.1" /root/common_files/nameservers_ipv4.txt > /root/common_files/nameservers_ipv4.txt_tmp; mv -f /root/common_files/nameservers_ipv4.txt_tmp /root/common_files/nameservers_ipv4.txt
grep -v "1\.0\.0\.1" /root/common_files/nameservers_ipv4.txt > /root/common_files/nameservers_ipv4.txt_tmp; mv -f /root/common_files/nameservers_ipv4.txt_tmp /root/common_files/nameservers_ipv4.txt
#Creo file nameserver cloudflare e google
echo '8.8.8.8' > /root/common_files/nameservers_google_cloudflare.txt
echo '8.4.4.8' >> /root/common_files/nameservers_google_cloudflare.txt
echo '1.1.1.1' >> /root/common_files/nameservers_google_cloudflare.txt
echo '1.0.0.1' >> /root/common_files/nameservers_google_cloudflare.txt

#Install altdns
echo "[+] Install AltDNS"
docker build -t "altdns:latest" https://github.com/energiatel/altdns.git

#Installo EyeWitness
echo "[+] Install EyeWitness"
docker build --build-arg user=$USER --tag eyewitness https://github.com/FortyNorthSecurity/EyeWitness.git

#Installo SubJack
#https://github.com/janmasarik/subjack/tree/patch-1
echo "[+] Install SubJack"
docker build -t subjack https://github.com/janmasarik/subjack.git

#Installo github-dork
#https://github.com/energiatel/github-dorks-docker/tree/master
#https://github.com/techgaun/github-dorks
echo "[+] Install github-dork"
docker build -t githubdorks https://github.com/energiatel/github-dorks-docker.git

#Installo meg
#https://github.com/tomnomnom/meg
#https://github.com/energiatel/meg
echo "[+] Install meg"
docker build -t meg https://github.com/energiatel/meg.git