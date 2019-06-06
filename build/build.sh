#!/bin/bash

version="3.9.4"
SSH="ssh -p 2222 root@deb.sambaedu.org"



if [ -z "$1" ]; then
	paquet="sambaedu-wpkg"
fi
debs="../${paquet}_${version}*.deb"
deb=$paquet
	
cd ../sources
rm -f $debs
dch -U -i ""
debuild -us -uc -b
$SSH "mkdir -p /root/tmpse4"
scp -P 2222 $debs root@deb.sambaedu.org:/root/tmpse4
$SSH "for deb in \$(ls /root/tmpse4/*.deb); do echo \"traitement de \$deb\"; reprepro -C se4XP -b /var/www/debian includedeb stretch \$deb; done"
$SSH "rm -fr /root/tmpse4"

#ssh root@admin.sambaedu3.maison "apt-get update && apt-get -y upgrade $deb"
cd
