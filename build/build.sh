#!/bin/bash

version="3.9.4"
if [ -z "$1" ]; then
	paquet="sambaedu-wpkg"
fi
debs="../${paquet}_${version}*.deb"
deb=$paquet
	
cd ../sources
rm -f $debs
dch -U -i ""
debuild -us -uc -b
scp -P 2222 $debs root@wawadeb.crdp.ac-caen.fr:/root/se4
ssh -p 2222 root@wawadeb.crdp.ac-caen.fr "se4/se4.sh $version"
#ssh root@admin.sambaedu3.maison "apt-get update && apt-get -y upgrade $deb"
cd