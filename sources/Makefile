#!/usr/bin/make -f
# Makefile for se3-wpkg

all:

install:
    # Add here commands to install the package into debian/sambaedu-wpkg.
	cp -R wpkg/* $(DESTDIR)/var/sambaedu/unattended/install/wpkg/
	# Fichiers de l'interface web de wpkg
	cp -R www/* $(DESTDIR)/var/www/sambaedu/wpkg/
	# Ajout de l'entree dans le menu (redondant avec 'Installation d'applications')
	cp menu.d_temp/98wpkg.inc $(DESTDIR)/var/www/sambaedu/includes/menu.d/
	cp -R scripts/* $(DESTDIR)/usr/share/sambaedu/scripts/
	# tools GPL
	cp -R tools/* $(DESTDIR)/var/sambaedu/unattended/install/wpkg/tools/
	# verif_wpkg
	[ -d $(DESTDIR)/var/sambaedu/Progs/install ] || mkdir -p $(DESTDIR)/var/sambaedu/Progs/install
	cp -R verif_wpkg/verif_wpkg.exe $(DESTDIR)/var/sambaedu/Progs/install/
	mkdir -p $(DESTDIR)/usr/share/doc/sambaedu-wpkg/
	cp -R doc/* $(DESTDIR)/usr/share/doc/sambaedu-wpkg/
clean:
