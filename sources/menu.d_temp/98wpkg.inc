<?
/* $Id$ */
$resultat=mysql_query("select login from delegation  where login='$login' and ( niveau='view' or niveau='manage');");
if(mysql_num_rows($resultat)==0){
	$liens1 = array(array(
	 gettext("Applications Windows"), "computers_is_admin|parc_can_manage|parc_can_view",3,
	 gettext("Déployer sur les parcs"), "wpkg/admin.html?PageEnCours=PackagesProfiles","computers_is_admin|parc_can_manage|parc_can_view",3,
	 gettext("Ajouter une application"), "wpkg/admin.html?PageEnCours=AjoutPackage","computers_is_admin",3,
	 gettext("Détail d'un parc"), "wpkg/admin.html?PageEnCours=AfficheProfile","computers_is_admin|parc_can_manage|parc_can_view",3,
	 gettext("Détail d'une application"), "wpkg/admin.html?PageEnCours=AffichePackage","computers_is_admin|parc_can_manage|parc_can_view",3,
	 gettext("Détail d'un poste"), "wpkg/admin.html?PageEnCours=AfficheHost","computers_is_admin|parc_can_manage|parc_can_view",3
	));
} else {
	$liens1 = array(array(
	 gettext("Applications Windows"), "",3,
	 gettext("Déployer sur les parcs"), "wpkg/admin.html?PageEnCours=PackagesProfiles","",3,
	 gettext("Ajouter une application"), "wpkg/admin.html?PageEnCours=AjoutPackage","computers_is_admin",3,
	 gettext("Détail d'un parc"), "wpkg/admin.html?PageEnCours=AfficheProfile","",3,
	 gettext("Détail d'une application"), "wpkg/admin.html?PageEnCours=AffichePackage","",3,
	 gettext("Détail d'un poste"), "wpkg/admin.html?PageEnCours=AfficheHost","",3
	));
}
if (file_exists("/var/www/se3/wpkg/WindowsUpdate.js")) {
	array_push ($liens1[0], gettext("Mises à jour Microsoft"), "wpkg/admin.html?PageEnCours=WindowsUpdate", "computers_is_admin", 3);
}
$liens=array_merge($liens,$liens1);
?>
