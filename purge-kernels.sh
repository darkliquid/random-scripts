#!/bin/bash

RED='\033[0;31m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

VER=$(uname -r | sed -r 's/-[a-z0-9A-Z]+$//')
OLD=$(sudo aptitude -F '%p' search linux-{image,headers,restricted}~i | grep -v $VER | grep -v "linux-headers-generic" | grep -v "linux-image-generic")

printf "\nCurrent kernel is ${CYAN}$VER${NC}\n"

if [ "" == "$OLD" ]; then
	printf "${GREEN}No older kernels to uninstall${NC}\n\n"
	exit
fi

echo "Going to uninstall the following packages:"
for pkg in $OLD; do
	echo $pkg
done

echo
printf "${RED}Press enter to continue, CTRL+C to abort${NC}\n\n"

read

echo $OLD | xargs sudo aptitude purge -y
