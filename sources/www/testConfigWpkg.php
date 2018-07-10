<?php

// ## $Id$ ##

header("Pragma: no-cache");
header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
include "inc/wpkg.auth.php";

// version du paquet debian
${config_se4fs_name}WPKGVERSION=exec("dpkg -p se3-wpkg | grep Version");

echo "var Debian = '${config_se4fs_name}WPKGVERSION';\r\n";
echo "var wpkgAdmin = ".($wpkgAdmin ? 1 : 0) . "; // Est-ce que l'utilisateur est un administrateur\r\n";
echo "var wpkgUser = ".($wpkgUser ? 1 : 0) . "; // Est-ce que l'utilisateur est autorisé à utiliser wpkg\r\n";
echo "var login = '".$login."';\r\n";
// Le package lsus est-il installé ?
if (file_exists("/var/www/sambaedu/wpkg/WindowsUpdate.js")) {
	echo "var lsusInstalled = true;\r\n";
} else {
	echo "var lsusInstalled = false;\r\n";
}
// L'interface du se3 intégre-t-elle les maj lors de la modification des Parcs ?
// Si OUI, les liens pour mettre à jour droits.xml, profiles.xml et hosts.xml ne sont pas affich�s.
exec ( "/bin/grep 'script_wpkg' /var/www/sambaedu/parcs/create_parc.php", $output, $return_value);
echo "var ShowParcsUpdateLink = " . ($return_value ? 'true' : 'false') . ";\r\n";
//echo "var ShowParcsUpdateLink = true;\n";
?>
// Teste si la configuration de wpkg a été effectuée par l'admin
function alertConfigWpkg () {
<?php      if ( file_exists("/var/sambaedu/Progs/ro/wpkgInstall.job" )) {
                echo "var wpkgInstalljob = true;\r\n";
        } else {
                echo "var wpkgInstalljob = false;\r\n";
        }
?>
	if ( ! wpkgInstalljob ) {
		alert("Wpkg n'a pas été correctement installé.\n" +
		"Le fichier 'L:\\ro\\wpkgInstall.job' est absent.\n\n" +
		"Pour terminer l'installation de wpkg, exécutez en root :\n" +
		"apt-get install -f\n" +
		"apt-get install se3-wpkg --reinstall\n" +
		"\nVous pourrez ensuite revenir à cette page...");
	}
}
	
