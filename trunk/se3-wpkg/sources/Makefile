#!/usr/bin/make -f
# Makefile for se3-wpkg

all:

install:
    # Add here commands to install the package into debian/Se3.
	cp -R wpkg/* $(DESTDIR)/var/se3/unattended/install/wpkg/
	# Fichiers de l'interface web de wpkg
	cp -R www/* $(DESTDIR)/var/www/se3/wpkg/
	# Ajout de l'entree dans le menu (redondant avec 'Installation d'applications')
	cp menu.d_temp/98wpkg.inc $(DESTDIR)/var/www/se3/includes/menu.d/
	cp install-scripts/* $(DESTDIR)/var/cache/se3_install/
	cp -R scripts/* $(DESTDIR)/usr/share/se3/scripts/
	# tools GPL
	cp -R tools/* $(DESTDIR)/var/se3/unattended/install/wpkg/tools/
	# verif_wpkg
	[ -d $(DESTDIR)/var/se3/Progs/install ] || mkdir -p $(DESTDIR)/var/se3/Progs/install
	cp -R verif_wpkg/verif_wpkg.exe $(DESTDIR)/var/se3/Progs/install/
clean:
