#!/usr/bin/gawk -f
BEGIN { 
	print "<?xml version='1.0' encoding='iso-8859-1'?>" 
	print "<!-- Généré par SambaEdu. Ne pas modifier -->" 
	print "<rapports>" 
}
{   sub("\r", "");
	if ( FNR == 2 ) Ligne = $0;
	if ( FNR == 4 ) Ligne = "";
	# print "<!-- FNR = " FNR " Ligne=" Ligne " -->";
	if ( FNR == 1 ) {
		PC="id=\"" $3 "\" ";
		#DATET=substr($1, 7, 4) "-" substr($1, 4, 2) "-" substr($1, 1, 2) " " $2;
		DATET="datetime=\"" substr($1, 7, 4) "-" substr($1, 4, 2) "-" substr($1, 1, 2) " " $2 "\" "
		DATEDAY="date=\"" $1 "\" ";
		#DATEDAY=$1;
		HEURE="time=\"" $2 "\" ";
		TYPEWIN="typewin=\"" $NF "\" ";
		
		MAC="";
		for ( i = 4; i < NF; i++) {
			IPMASK=$(i+1);
			gsub("[)(]", "", IPMASK);
			# print "<!-- 0 = " $0 "\nNF=" NF " i = " i " IPMASK = " IPMASK " -->";
			if ( IPMASK ~ /^0.0.0.0/ ) {
				while ( ( $(++i) !~ /.*)$/ ) && (i < NF)) ;
			} else{
				MAC=$i;
				i=NF;
			}
		}
		MAC="mac=\"" MAC "\" ";
		split(IPMASK, a, "/");
		IP="ip=\"" a[1] "\" ";
		if (a[2] != "") MASK="mask=\"" a[2] "\" ";
		else MASK="";
		gsub("/.*", "", IP);
		gsub(".*/", "", MASK);
		# print "  <!-- ARGIND=" ARGIND " -->";
		if ( InRapport == 1 ) {
			if ( Ligne != "" ) {
				gsub("\"", "\\&#39;", Ligne);
				print "<erreur str=\"" Ligne "\" />";
			}
			print "  </rapport>";
			InRapport = 0;
		}
		if ( (PC != "") && ( $5 != "") ) {
			LogFile=FILENAME;
			sub("\\.txt$", ".log", LogFile);
			
			if ( ! system ( "test -e " LogFile ) ) {
				LogFile="logfile=\"" LogFile "\" ";
			} else {
				LogFile="";
				#print "  <rapport id=\"" PC "\" datetime=\"" DATET "\" date=\"" DATEDAY "\" time=\"" HEURE "\" mac=\"" MAC "\" ip=\"" IP "\" mask=\"" MASK "\" typewin=\"" TYPEWIN "\">";
			}
			print "  <rapport " PC DATET DATEDAY HEURE MAC IP MASK TYPEWIN LogFile ">";
			PC="";
			InRapport=1;
		} else {
			print "    <!-- Erreur Ligne 1 du rapport " FILENAME " non conforme -->";
			nextfile
		}
		nChamps=0;
		next;
	}
}
/^    .+: / {
	InPackage=1;
	nChamps++;
	if ( $1 == "ID:"       ) { ID       = valeur(); next }
	if ( $1 == "Revision:" ) { Revision = valeur(); next }
	if ( $1 == "Reboot:"   ) { Reboot   = valeur(); next }
	if ( $1 == "Status:"   ) { Status   = valeur(); next }
}
/^$/ {
	# print "  <!-- Ligne vide InPackage=" InPackage ", nChamp=" nChamp " -->";
	if ( InPackage == 1 ) {
		if ( nChamps == 4 ) {
			print "    <package id=\"" ID "\" revision=\"" Revision "\" reboot=\"" Reboot "\" status=\"" Status "\" />";
		} else {
			print "    <!-- Erreur nChamps=" nChamps " -->";
			nextfile
		}
		InPackage = 0;
		nChamps=0;
		next;
	}
}
END {
	# print "  <!-- END InRapport=" InRapport " -->";
	if ( InRapport == 1 ) {
		if ( Ligne != "" ) {
			gsub("\"", "\\&#39;", Ligne);
			print "<erreur str=\"" Ligne "\" />";
		}
		print "  </rapport>"
	}
}
function valeur() {
	if (NF >= 2) {
		$1="";
		sub("^ ", "");
		return $0;
	} else {
		return "";
	}
}
END { print "</rapports>" }