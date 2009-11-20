<?xml version="1.0" encoding="iso-8859-1"?>
<!--  Création du tableau Packages, Profiles pour indiquer les associations 
		S'applique à wpkg.xml
		
	## $Id$ ##
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" encoding="utf-8" />
	<xsl:param name="login" select="''" />
	<xsl:param name="Navigateur" ><xsl:text>inconnu</xsl:text></xsl:param>
	<xsl:param name="Debug" select="false()" />
	<xsl:param name="Local" select="false()" />
	<xsl:param name="sortPackages" select="'ascending'" />
	<xsl:param name="sortProfiles" select="'ascending'" />
	
	<xsl:key name="PackageFromId" match="/wpkg/packages/package" use="@id" />
	<xsl:key name="ProfileFromId" match="/wpkg/profiles/profile" use="@id" />
	<xsl:key name="ProfilePackage" match="/wpkg/profiles/profile/package" use="concat(../@id, ':', @package-id)" />
	
	<xsl:variable name="PROFILES" select="/wpkg/profiles"/>
	<xsl:variable name="PACKAGES" select="/wpkg/packages"/>
	<xsl:variable name="HOSTS" select="/wpkg/hosts"/>
	
	<xsl:variable name="ListProfilesCanRead" select="$PROFILES/profile[not(depends/@profile-id = '_TousLesPostes')]"/>
	<xsl:variable name="TousLesParc" select="key('ProfileFromId', '_TousLesPostes') | $ListProfilesCanRead"/>
	<xsl:variable name="ListProfilesCanWrite" select="$ListProfilesCanRead[@canWrite = '1']"/>
	
	<xsl:variable name="nbHosts">
		<xsl:value-of select="count($HOSTS/host)"/>
	</xsl:variable>
	<xsl:variable name="nbProfiles">
		<xsl:value-of select="count($ListProfilesCanRead)"/>
	</xsl:variable>
	<xsl:variable name="nbPackages">
		<xsl:value-of select="count($PACKAGES/package)"/>
	</xsl:variable>
	
	<xsl:variable name="HLigneTitre" select="'120'"/> <!-- Hauteur de la ligne de Titre (packages) -->
	<xsl:variable name="LColTitre" select="'120'"/>   <!-- Largeur de la colonne de Titre (profiles) -->
	<xsl:variable name="Lcase" select="'24'"/>  <!-- Largeur d'une case du tableau -->
	<xsl:variable name="Hcase" select="'24'"/>  <!-- Hauteur d'une case du tableau -->
	<xsl:variable name="LTable">  <!-- Largeur du tableau (cases)-->
		<xsl:choose >
			<xsl:when test = "$Navigateur = 'ie'" >
				<xsl:value-of select="$nbProfiles * $Lcase" />
			</xsl:when> 
			<xsl:otherwise>
				<xsl:value-of select="($nbProfiles + 5) * $Lcase" />
			</xsl:otherwise>
		</xsl:choose >
	</xsl:variable>
	<xsl:variable name="HTable" select="$nbPackages * $Hcase" />  <!-- Hauteur du tableau (cases)-->
	
	<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	
	<xsl:template match="/">
		<xsl:if test="$Debug">
			<pre>
				login=<xsl:value-of select="$login" />
				Debug=<xsl:value-of select="$Debug" />
				nbHosts=<xsl:value-of select="$nbHosts" />
				nbProfiles=<xsl:value-of select="$nbProfiles" />
				nbPackages=<xsl:value-of select="$nbPackages" />
				nbProfilesCanRead=<xsl:value-of select="$nbProfiles" />
				nbProfilesCanWrite=<xsl:value-of select="count($ListProfilesCanWrite)" />

			</pre>
		</xsl:if>
		<div style="position:relative;left:0px;top:0px;width:{$HLigneTitre + $LTable}px;height:{$LColTitre + $HTable}px;z-index:0;">
			<!-- Affiche la 1ère ligne (Titres des colonnes = Profiles) -->
			<xsl:call-template name="TitresProfiles" />
			<!-- div contenant la 1ère colonne (liste des id de package) -->
			<div id="PosX" style="position:absolute;left:0px;top:{$HLigneTitre}px;">
				<div id="ClipY" style="overflow: hidden;position:absolute;top:0px;left:0px;width:{$LColTitre + 5}px;height:{($nbPackages)*$Hcase}px;">
					<div id="ScrollY" style="position:absolute;top:0px;left:0px;width:{$LColTitre + 5}px;height:{($nbPackages)*$Hcase}px;">
						<xsl:for-each select="$PACKAGES/package">
							<xsl:sort select="translate(@id, $ucletters, $lcletters)" order="{$sortPackages}" />
							<xsl:variable name="iPack" select="position()"/>
							<xsl:call-template name="caseTitrePackage">
								<xsl:with-param name="idPackage" select="@id" />
								<xsl:with-param name="iPackage" select="$iPack" />
							</xsl:call-template>
						</xsl:for-each>
					</div>
				</div>
				<!-- Bouton de tri des applis -->
				<input value=" Tri " title="Trier les applications." type="button" 
						onclick="sortPackages=(sortPackages==&quot;ascending&quot;)?&quot;descending&quot;:&quot;ascending&quot;;ChangePageEnCours('PackagesProfiles', true);setTimeout('scroll();', 400);"
						style="position:absolute;top:-25px;left:10px;font-size:xx-small;cursor:pointer;">
				</input>
			</div>
			
			<!-- Affichage des cases cochées ou non selon l'affectation -->
			<!-- div contenant toutes les cases ( associations ) -->
			<div style="position:absolute;left:{$LColTitre+5}px;top:{$HLigneTitre+1}px;border:none;height:{$HTable}px;width:{$LTable}px;">
				<div id="PosXY" style="position:absolute;top:0px;left:0px;">
					<div id="ClipXY" style="overflow: hidden;position:absolute;top:0px;left:0px;height:{$HTable}px;width:{$LTable}px;">
						<div id="ScrollXY" style="position:absolute;top:0px;left:0px;">
							<xsl:for-each select="$TousLesParc">
								<xsl:sort select="translate(@id, $ucletters, $lcletters)" order="{$sortProfiles}" />
								<!-- seuls les profiles ne dépendant pas de 'TousLesPostes' sont affichés.
										En clair : seuls les parcs sont indiqués ( les profils des postes sont masqués ) -->
								<xsl:call-template name="PackagesDeCeProfile">
									<xsl:with-param name="idProfile" select="@id" />
									<xsl:with-param name="iProfile" select="position()" />
								</xsl:call-template>
							</xsl:for-each>
						</div>
					</div>
				</div>
			</div>
		</div>
	</xsl:template>
	
	<xsl:template name="PackagesDeCeProfile">
		<!-- Affiche les cases cochées ou non pour les Packages activés de ce profile -->
		<xsl:param name="idProfile" />
		<xsl:param name="iProfile" />
		<xsl:variable name="ProfileEnCours" select="key('ProfileFromId', $idProfile)"/>
		<xsl:variable name="canWrite" select="$ProfileEnCours/@canWrite"/>
		<xsl:for-each select="$PACKAGES/package">
			<xsl:sort select="translate(@id, $ucletters, $lcletters)" order="{$sortPackages}" />
			<xsl:variable name="idPackage" select="@id"/>
			<xsl:variable name="iPackage" select="position()"/>
			<!-- Protection de ', remplacé par ¤ -->
			<xsl:variable name="idCase" select="concat($idProfile, ':', $idPackage)"/>
			<!--  Affiche une case qui indique l'état activé ou non de cette appli pour ce profil -->
			<xsl:element name="div">
				<xsl:attribute name="class">
					<xsl:choose>
						<xsl:when test="$canWrite">
							<xsl:text>CasePackageProfile</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>CasePackageProfileReadOnly</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:attribute name="style">
					<xsl:text>
						/* background-color:#F0F8FF; */
						</xsl:text>
							<!-- A remplacer par des images ou icônes -->
							<xsl:choose>
								<xsl:when test="key('ProfilePackage', $idCase)">
									<!-- installer -->
									<xsl:text>background-color:#6699CC;z-index:4;</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<!-- NE PAS installer -->
									<xsl:text>background-color:#F0F8FF;z-index:3;</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						<xsl:text>
						top:</xsl:text><xsl:value-of select="($iPackage - 1) * $Hcase + 2" /><xsl:text>px;
						left:</xsl:text><xsl:value-of select="($iProfile - 1) * $Lcase + 2" /><xsl:text>px;
					</xsl:text>
				</xsl:attribute>
				<xsl:attribute name="align"><xsl:text>center</xsl:text></xsl:attribute>
				<xsl:attribute name="title">
					<xsl:value-of select="concat($idPackage, ' -&gt; ', $idProfile)"/>
				</xsl:attribute>
				<xsl:choose>
					<xsl:when test="$canWrite">
						<xsl:attribute name="onclick">
							<xsl:text>PP(event,&quot;</xsl:text><xsl:value-of select="$idCase" /><xsl:text>&quot;);</xsl:text>
						</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>x</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="TitresProfiles">
		<!-- Ligne Titre des lignes (Nom des profiles) -->
		<!-- div contenant la 1ère ligne Titres (liste des id de profiles) -->
		<div id="PosY" style="position:absolute;left:{$LColTitre + 4}px;top:-10px;height:{$HLigneTitre + 10}px;z-index:2;">
			<!-- div 'Liste des parcs' à décaler verticalement à chaque scroll pour qu'il soit toujours visible -->
			<div id="ClipX" style="overflow: hidden;position:absolute;top:0px;left:0px;width:{$LTable}px;height:{$HLigneTitre + 10}px;">
				<div id="ScrollX" style="position:relative;top:0px;left:0px;width:{$LTable}px;height:{$HLigneTitre + 10}px;">
					<xsl:for-each select="$TousLesParc">
						<xsl:sort select="translate(@id, $ucletters, $lcletters)" order="{$sortProfiles}" />
						<!-- seuls les profiles ne dépendant pas de '_TousLesPostes' sont affichés.
									En clair : seuls les parcs sont indiqués ( les profils des postes sont masqués ) -->
						<xsl:choose >
							<xsl:when test = "$Navigateur='ie'" >
								<xsl:call-template name="CaseTitreProfileIE">
									<xsl:with-param name="iPack" select="position()" />
									<xsl:with-param name="idProfile" select="@id" />
								</xsl:call-template>
							</xsl:when> 
							<xsl:otherwise>
								<xsl:call-template name="CaseTitreProfileFireFox">
									<xsl:with-param name="iPack" select="position()" />
									<xsl:with-param name="idProfile" select="@id" />
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose >
					</xsl:for-each>
				</div>
			</div>
			<!-- Bouton de tri des parcs -->
			<input value=" Tri " title="Trier les parcs." type="button" 
					onclick="sortProfiles=(sortProfiles==&quot;ascending&quot;)?&quot;descending&quot;:&quot;ascending&quot;;ChangePageEnCours('PackagesProfiles', true);setTimeout('scroll();', 400);"
					style="position:absolute;top:10px;left:-40px;font-size:xx-small;cursor:pointer;">
			</input>
			<!-- img src="img/wpkg.png" style="position:absolute;top:25px;left:-145px;font-size:xx-small;" / -->
		</div>
	</xsl:template>
	
	<xsl:template name="CaseTitreProfileFireFox">
		<!-- Affiche un Titre d'une colonne (Profile) pour FireFox -->
		<xsl:param name="iPack" />
		<xsl:param name="idProfile" />
		<!-- Je ne sais pas afficher du texte vertical avec firefox donc j'ai fait un truc un peu compliqué :
					 Affichage en escalier sur 4 Id -->
		<xsl:element name="div">
			<!-- div VerticalGauche -->
			<xsl:attribute name="class"><xsl:text>CaseTitreProfileFireFox</xsl:text></xsl:attribute>
			<xsl:attribute name="style">
				<xsl:text>
					left:</xsl:text><xsl:value-of select="($iPack - 1) * $Lcase + 3" /><xsl:text>px;
					width:4px;
					z-index:</xsl:text><xsl:value-of select="(($iPack -1) mod 5)" /><xsl:text>;
					top:</xsl:text><xsl:value-of select="((($iPack + 4) mod 5) * ($HLigneTitre div 4.8)) " /><xsl:text>px;
					height:</xsl:text><xsl:value-of select="($HLigneTitre - 8) - ((($iPack + 4) mod 5) * ($HLigneTitre div 4.8)) + 10" /><xsl:text>;
				</xsl:text>
			</xsl:attribute>
			<xsl:attribute name="onclick">
				<xsl:value-of select="concat('defProfile(&quot;',$idProfile,'&quot;)')" />
			</xsl:attribute>
		</xsl:element>
		<xsl:element name="div">
			<!-- div HorizontalHaut (contient le nom du profile) -->
			<xsl:attribute name="class"><xsl:text>CaseTitreProfileFirefox</xsl:text></xsl:attribute>
			<xsl:attribute name="style">
				<xsl:text>
					left:</xsl:text><xsl:value-of select="($iPack - 1) * $Lcase + 3" /><xsl:text>px;
					z-index:</xsl:text><xsl:value-of select="(($iPack -1) mod 5)" /><xsl:text>;
					top:</xsl:text><xsl:value-of select="((($iPack + 4) mod 5) * ($HLigneTitre div 4.8))" /><xsl:text>px;
					height:</xsl:text><xsl:value-of select="$Hcase - 9" /><xsl:text>;
					width:auto;
				</xsl:text>
			</xsl:attribute>
			<!-- <xsl:attribute name="align"><xsl:text>left</xsl:text></xsl:attribute> -->
			<xsl:attribute name="id"><xsl:value-of select="$idProfile" /></xsl:attribute>
			<xsl:attribute name="title">
				<xsl:value-of select="concat('Le parc &quot;', $idProfile, '&quot; contient ', count($PROFILES/profile/depends[@profile-id = $idProfile]), ' poste(s)')"/>
			</xsl:attribute>
			<xsl:attribute name="onclick">
				<xsl:value-of select="concat('defProfile(&quot;',$idProfile,'&quot;)')" />
			</xsl:attribute>
		
			<xsl:value-of select="$idProfile"/>
			
		</xsl:element>
		
	</xsl:template>

	<xsl:template name="CaseTitreProfileIE">
		<!-- Affiche un Titre d'une colonne (profile) pour IE -->
		<xsl:param name="iPack" />
		<xsl:param name="idProfile" />
		<xsl:element name="div">
			<xsl:attribute name="class"><xsl:text>CaseTitreProfileIE</xsl:text></xsl:attribute>
			<xsl:attribute name="style">
				<xsl:text>
					left:</xsl:text><xsl:value-of select="($iPack - 1) * $Lcase" /><xsl:text>px;
				</xsl:text>
				<xsl:text>
					writing-mode : tb-rl;
					filter: flipH() flipV();
					top:0px;
				</xsl:text> 
			</xsl:attribute>
			<xsl:attribute name="align"><xsl:text>left</xsl:text></xsl:attribute>
			<xsl:attribute name="id"><xsl:value-of select="$idProfile" /></xsl:attribute>
			<xsl:attribute name="title">
				<xsl:value-of select="concat('Contient ', count(../profile/depends[@profile-id = $idProfile]), ' poste(s)')"/>
			</xsl:attribute>
			<xsl:attribute name="onclick">
				<xsl:value-of select="concat('defProfile(&quot;',$idProfile,'&quot;)')" />
			</xsl:attribute>
			<xsl:value-of select="$idProfile"/>
		</xsl:element>
		
	</xsl:template>

	<xsl:template name="caseTitrePackage">
		<!-- Affiche un Titre de package dans la 1ère colonne -->
		<xsl:param name="iPackage" />
		<xsl:param name="idPackage" />
		<xsl:element name="div">
			<xsl:attribute name="id"><xsl:value-of select="$idPackage"/></xsl:attribute>
			<xsl:attribute name="class">
				<xsl:text>caseTitrePackage</xsl:text>
			</xsl:attribute>
			<xsl:attribute name="style"><xsl:text>
				top:</xsl:text><xsl:value-of select="($iPackage - 1) * $Hcase " /><xsl:text>px;
				width:</xsl:text><xsl:value-of select="$LColTitre - 2" /><xsl:text>px;
				</xsl:text>
			</xsl:attribute>
			<xsl:attribute name="onclick">
				<xsl:value-of select="concat('defPackage(&quot;',$idPackage,'&quot;)')" />
			</xsl:attribute>
			<xsl:attribute name="align"><xsl:text>right</xsl:text></xsl:attribute>
			<xsl:attribute name="title">
				<xsl:value-of select="concat(@name, ' (Rev:', @revision,')')" />
			</xsl:attribute>
			<xsl:value-of select="$idPackage" />
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>
