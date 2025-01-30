#!/bin/bash
# Bash Script for tunning Apache Web Server

echo -e "-=[ Made by nzucode \t\t]=-"
echo -e "-=[ https://seno21.github.io \t]=- \n"


echo -e "####### CHECKING #######"
if command -v apache2 >/dev/null 2>&1; then
    echo -e "\e[32m[+] Apache2 terinstall\e[0m"
else
    echo -e "\e[31m[-] Apache tidak ditemukan\e[0m"
    exit
fi

if systemctl is-active --quiet apache2; then
        echo -e "\e[32m[+] Apache2 aktif\e[0m"
    else
        echo -e "\e[31m[-] Apache tidak aktif\e[0m"
        exit
    fi

if apache2ctl -M | grep -q 'mpm_prefork_module'; then
    echo -e "\e[32m[+] Modul mpm_prefork aktif\e[0m"
else
    echo -e "\e[31m[+] Modul mpm_prefork tidak aktif\e[0m"
    exit
fi


if command -v php &> /dev/null; then
    php_version=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+\.[0-9]+')
    echo -e "\e[32m[+] PHP terinstal. Versi: $php_version\e[0m"
else
    echo -e "\e[31m[-] PHP tidak terinstal.\e[0m"
    exit 1
fi


echo -e "\e[0m\n####### REQUIREMENT #######\n"
read -p "Memory System (Dalam satuan MB) : " sys

if ! [[ $sys =~ ^[0-9]+$ ]]; then
    echo -e "\e[31mInput tidak valid!\e[0m"
    exit
fi

system=$sys  
float_avg=$(ps -ylC apache2 | awk '{x += $8;y += 1} END {print x/((y-1)*1024)}')
avg=$(echo $float_avg | awk '{print int($1)}')
total=$(free | awk '/^Mem:/ {print $2/1024}')
apache=$(ps -ylC apache2 | awk '{x += $8;y += 1} END {print x/1024;}')

rumus=$(echo "scale=0; ($total - $system) / $avg" | bc)

if [ $rumus -lt 0 ]; then
    echo -e "\e[31m[-] Ram tidak sesuai\e[0m"
    exit 1
fi

file=mpm_prefork.conf.backup
if [ -f "${file}" ]; then
    cp $file mpm_prefork.conf
    filenew=mpm_prefork.conf
    server=$(echo -e "\tServerLimit \t\t\t$rumus")
    worker=$(echo -e "\tMaxRequestWorkers \t$rumus")
    sed -i "2i $server " $filenew
    sed -i "3i $worker " $filenew
else 
    echo -e "\e[31m[-] Master File tidak ditemukan\e[0m"
    exit
fi

echo -e "\n ======= Detail ======="
echo -e "Pemakaian Memory Apache \t:$apache MB"
echo -e "Kebutuhan Memory System \t:$sys MB"
echo -e "Total Memory \t\t\t:$total MB"
echo -e "Rata-rata Proses Apache \t:$avg MB"

echo -e "\n ======= Tunning Apache2 ======="
# Copy file dan reload apache
tgl=$(date +%d%m%Y)
mv /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf.${tgl} 
cp mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf
a2enmod mpm_prefork > tune.log

# Hasil tunning
echo -e "\e[32m[+]MaxRequestWorkers & ServerLimit set on $rumus \e[0m"

systemctl restart apache2
if [ $? -eq 0 ]; then
    echo -e "\e[32m[+] Tunning Apache2 Success\e[0m"
else
    echo -e "\e[31m[+] Tunning Apache2 Failed\e[0m"
fi
# Apache Tunning success