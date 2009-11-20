<?
// ## $Id$ ##
header("Pragma: no-cache");
header("Cache-Control: max-age=5, s-maxage=5, no-cache, must-revalidate");
include "inc/wpkg.auth.php";

// version du paquet debian
$SE3WPKGVERSION='se3-wpkg_0.1-19_i386.deb';

echo "var Debian = '$SE3WPKGVERSION';\r\n";
echo "var wpkgAdmin = ".($wpkgAdmin ? 1 : 0) . "; // Est-ce que l'utilisateur est un administrateur\r\n";
echo "var wpkgUser = ".($wpkgUser ? 1 : 0) . "; // Est-ce que l'utilisateur est autorisé à utiliser wpkg\r\n";
echo "var login = '".$login."';\r\n";
// Le package lsus est-il installé ?
if (file_exists("/var/www/se3/wpkg/WindowsUpdate.js")) {
	echo "var lsusInstalled = true;\r\n";
} else {
	echo "var lsusInstalled = false;\r\n";
}
// L'interface du se3 intègre-t-elle les maj lors de la modification des Parcs ?
// Si OUI, les liens pour mettre à jour droits.xml, profiles.xml et hosts.xml ne sont pas affichés.
exec ( "/bin/grep 'script_wpkg' /var/www/se3/parcs/create_parc.php", $output, $return_value);
echo "var ShowParcsUpdateLink = " . ($return_value ? 'true' : 'false') . ";\r\n";
//echo "var ShowParcsUpdateLink = true;\n";
?>
// Teste si la configuration de wpkg a été effectuée par l'admin
function alertConfigWpkg () {
<?      if ( file_exists("/var/se3/Progs/ro/wpkgInstall.job" )) {
                echo "var wpkgInstalljob = true;\r\n";
        } else {
                echo "var wpkgInstalljob = false;\r\n";
        }
?>
	if ( ! wpkgInstalljob ) {
		alert("Wpkg n'a pas été configuré par l'admin.\n" +
		"Le fichier 'L:\\ro\\wpkgInstall.job' est absent.\n\n" +
		"Pour configurer wpkg pour votre réseau, exécutez :\n" +
		"L:\\install\\wpkg-config.bat\n" +
		"\nVous pourrez ensuite revenir à cette page...");
	}
}
	
