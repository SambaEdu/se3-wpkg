#!/usr/bin/make -f
# Makefile for sambaedu-wpkg

all:

install:
    # Add here commands to install the package into debian/sambaedu-wpkg.
	cp -R var/sambaedu/unattended/install/wpkg/* $(DESTDIR)/var/sambaedu/unattended/install/wpkg/
	# Fichiers de l'interface web de wpkg
	cp -R var/www/sambaedu/* $(DESTDIR)/var/www/sambaedu/
	cp -R usr/share/sambaedu/scripts/* $(DESTDIR)/usr/share/sambaedu/scripts/
	cp -R usr/share/doc/sambaedu-wpkg/* $(DESTDIR)/usr/share/doc/sambaedu-wpkg/
	
	# tools GPL
	#cp -R tools/* $(DESTDIR)/var/sambaedu/unattended/install/wpkg/tools/
clean:
