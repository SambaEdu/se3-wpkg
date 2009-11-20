<?php
$wpkgUser = false;
include "inc/wpkg.auth.php";

if ( ! $wpkgUser ) {
    include entete.inc.php; ?>
        <h2>Déploiement d'applications</h2>
        <div class=error_msg>Vous n'avez pas les droits nécessaires à l'utilisation de cette fonction !</div>
<?  include pdp.inc.php;
    exit;
} else{
    if ($_GET["Poste"] == '') Erreur("poste non défini");
    elseif  ($_GET["Broadcast"] == '') Erreur("Broadcast non défini");
    elseif  ($_GET["Mac"] == '') Erreur("Mac non défini");
    elseif  ($_GET["Ip"] == '') Erreur("Ip non défini");
	else {
		// envoi d'une trame wakeonlan
	    exec ( "/usr/bin/wakeonlan -i '".$_GET["Broadcast"]."' '" . $_GET["Mac"] . "' 2>&1", $output, $status );
		$msg="wakeonlan  -i '".$_GET["Broadcast"]."' '" . $_GET["Mac"] . "'\n";
		
		// Pour le cas où le poste était déjà démarré
		exec ( "net rpc shutdown -r -f -C 'Redemarrage pour wpkg' -S ".$_GET["Poste"]." -U '".$_GET["Poste"]."\adminse3%$xppass' 2>&1", $output, $status );
		if ( $status == 0 ) {
			print "Redemarrge du '$Poste' : OK\n\n";
			print "net rpc shutdown -r -f -C 'Redemarrage pour wpkg' -S '".$_GET["Poste"]."' -U '".$_GET["Poste"]."\adminse3%XXXXXX'\n";
			return true;
		} else {
			$msg .= "Redemarrage du poste $Poste ... \n";
			$msg .= "Erreur $status : net rpc shutdown -r  -f -C 'Redemarrage pour wpkg' -S '".$_GET["Poste"]."' -U '".$_GET["Poste"]."\adminse3%XXXXXX'\n";
			$msg .= "\n";
			foreach($output as $key => $value) {
				$msg .= "   $value\n";
			}
			$msg .= "\n";
			// Essai avec ssh adminse3

			//$rebootCmd = "(shutdown.exe -r -f)||(psshutdown.exe -r -f -n 10)";
			$rebootCmd = "shutdown.exe -r -f";
			$sshCmd = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o CheckHostIP=no -i /var/remote_adm/.ssh/id_rsa";
			
			//echo "$sshCmd adminse3@".$_GET["Ip"]." '$rebootCmd'";
			exec ( "$sshCmd adminse3@".$_GET["Ip"]." '$rebootCmd' 2>&1", $output, $status );
			if ( $status == 0 ) {
				print "Redemarrge du '$Poste' : OK\n\n";
				print "$sshCmd adminse3@".$_GET["Ip"]." '$rebootCmd'\n";
				return true;
			} else {
				$msg .= "Erreur $status : $sshCmd adminse3@".$_GET["Ip"]." '$rebootCmd'\n";
				$msg .= "\n";
				foreach($output as $key => $value) {
					$msg .= "   $value\n";
				}
				$msg .= "\n";
				// Essai avec ssh administrateur
				exec ( "$sshCmd leb@".$_GET["Ip"]." '$rebootCmd' 2>&1", $output, $status );
				if ( $status == 0 ) {
					print "Redemarrge du '$Poste' : OK\n\n";
					print "$sshCmd administrateur@".$_GET["Ip"]." '$rebootCmd'\n";
					return true;
				} else {
					//header("HTTP/1.1 505 Forbidden");
					//header("Status: 505 Erreur d'execution"); 
					$msg .= "Erreur $status : $sshCmd administrateur@".$_GET["Ip"]." '$rebootCmd'\n";
					$msg .= "\n";
					foreach($output as $key => $value) {
						$msg .= "   $value\n";
					}
					$msg .= "\n";
					header("HTTP/1.1 505 Forbidden");
					header("Status: 505 Erreur d'execution"); 
					echo "$msg";
					return false;
				}
			}
		}
	}
}
function Erreur($msg) {
    header("HTTP/1.1 404 Not found");
    header("Status: 404 Not found"); 
    echo "$msg\n";
}

?>
