<?xml version="1.0" encoding="iso-8859-1"?>

<!--  Définition d'un profile avec affichage de l'état des postes de ce profile 
		S'applique à wpkg.xml
		
		## $Id$ ##
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!--xsl:output method="html" encoding="utf-8" / -->
	<xsl:output method="html" encoding="iso-8859-1" />
	<xsl:param name="login" select="''" />
	<xsl:param name="Navigateur" select="'inconnu'" />
	<xsl:param name="Debug" select="false()" />
	<xsl:param name="idProfile" select="''" />
	
	<xsl:variable name="PROFILES" select="/wpkg/profiles"/>
	<xsl:variable name="RAPPORTS" select="/wpkg/rapports"/>
	<xsl:variable name="PACKAGES" select="/wpkg/packages" />
	
	<xsl:key name="rapportFromHostid" match="/wpkg/hosts/host/rapport" use="../@name" />
	<xsl:key name="PackageFromId" match="/wpkg/packages/package" use="@id" />
	<xsl:key name="ProfileFromId" match="/wpkg/profiles/profile" use="@id" />
	<xsl:key name="RapportRevision" match="/wpkg/hosts/host/rapport/package" use="concat(../@id, ':', @id)" />
	
	<xsl:variable name="isWpkgAdmin" select="key('ProfileFromId', '_TousLesPostes')/@canWrite = '1'"/>
	
	<xsl:variable name="ListProfilesCanRead" select="$PROFILES/profile[not(depends/@profile-id = '_TousLesPostes')]"/>
	<xsl:variable name="ListProfilesCanWrite" select="$ListProfilesCanRead[@canWrite = '1']"/>
	<!-- Liste des postes de ce profile -->
	<xsl:variable name="ListPostes" select="$PROFILES/profile[depends/@profile-id = $idProfile]"/>
	
	<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	
	<xsl:template match="/">
		<xsl:if test="$Debug">
			<pre>
				idProfile=<xsl:value-of select="$idProfile" />
				nbListProfilesCanRead=<xsl:value-of select="count($ListProfilesCanRead)" />
				Navigateur=<xsl:value-of select="$Navigateur" />
			</pre>
		</xsl:if>
		<xsl:element name="div">
			<xsl:attribute name="id">Resultat</xsl:attribute>
			<!-- Sélection d'un autre profile -->
			<h2>Parc à afficher : 
				<select class="SelectH3" id="idProfile" name="idProfile" >
					<xsl:attribute name="onchange">
						<xsl:value-of select="'defProfile(this.value);'" />
					</xsl:attribute>
					<xsl:if test="$idProfile = ''">
						<option value="''" selected="true()"><xsl:value-of select="'Choisir le parc...'" /></option>
					</xsl:if>
					<xsl:choose>
						<xsl:when test="$idProfile = '_TousLesPostes'">
							<option value="_TousLesPostes" selected="true()"><xsl:value-of select="'_TousLesPostes'" /></option>
						</xsl:when>
						<xsl:otherwise>
							<option value="_TousLesPostes"><xsl:value-of select="'_TousLesPostes'" /></option>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:for-each select="$ListProfilesCanRead">
						<xsl:sort select="translate(@id, $ucletters, $lcletters)" order="ascending" />
						<xsl:choose>
							<xsl:when test="@id = '_TousLesPostes'">
							</xsl:when>
							<xsl:when test="@id = $idProfile">
								<option value="{@id}" selected="true()"><xsl:value-of select="@id" /></option>
							</xsl:when>
							<xsl:otherwise>
								<option value="{@id}"><xsl:value-of select="@id" /></option>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</select>
			</h2>
		</xsl:element>
		<xsl:element name="div">
			<xsl:choose>
				<xsl:when test="$idProfile = ''">
					<!-- Pas de Parc sélectionné -->
					<xsl:text> Pas de Parc sélectionné </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<!-- Parc $idProfile sélectionné -->
					<xsl:variable name="CeProfile" select="key('ProfileFromId', $idProfile)" />
					<xsl:variable name="nbPostes" select="count($ListPostes)" />
					<div style="font-size:small;" >
						<xsl:choose>
							<xsl:when test="$nbPostes = '0'">
								<xsl:text> 0 poste Windows 2000 ou XP dans le parc </xsl:text><b><xsl:value-of select="$idProfile" /></b><br></br> 
							</xsl:when>
							<xsl:when test="$nbPostes = '1'">
								<xsl:text> 1 poste Windows 2000 ou XP dans le parc </xsl:text><b><xsl:value-of select="$idProfile" /></b><br></br> 
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$nbPostes" /><xsl:text> poste(s) Windows 2000 ou XP dans le parc </xsl:text><b><xsl:value-of select="$idProfile" /></b><br></br> 
							</xsl:otherwise>
						</xsl:choose>
					</div>
					<!-- Liste des postes concernés par ce profile (=Parc) -->
					<div id="divTableau">
						<!-- Nom du profile et dépendances -->
						<table class="postes">
							<thead id="headTableau">
								<tr>
									<th style="cursor:ne-resize;" onclick="tri(1,event);">Poste</th>
									<th style="cursor:ne-resize;" onclick="tri(2,event);" title="Nbre d'appli. installées / Nbre d'appli. souhaitées" >Nbre d'appli.</th>
									<th style="cursor:ne-resize;" onclick="tri(3,event);" title="Correspondance entre l'état souhaité et actuel du poste">Synchro.</th>
									<th style="cursor:ne-resize;" onclick="tri(4,event);">Date du dernier rapport</th>
									<th style="cursor:ne-resize;" onclick="tri(5,event);">Adresse MAC</th>
									<th style="cursor:ne-resize;" onclick="tri(6,event);">Adresse IP</th>
								</tr>
							</thead>
							<tbody id="bodyTableau">
							</tbody>
						</table>
					</div>
					<script id="ScriptTableau" type="text/javascript"><xsl:text>Tableau = new Array();&#xa;</xsl:text>
						<xsl:for-each select="$ListPostes" >
							<xsl:sort select="translate(@id, $ucletters, $lcletters)" />
							<xsl:variable name="idPoste" select="@id"/>
							<xsl:variable name="CePoste" select="key('rapportFromHostid', $idPoste)"/>
							
							<!-- Profile de idHost -->
							<xsl:variable name="profileHost" select="key('ProfileFromId', $idPoste)" />
							<xsl:variable name="profileDependsId" select="key('ProfileFromId', ($idPoste | $profileHost/depends/@profile-id))/package/@package-id" />
							<!-- Nombre de packages à installer demandés pour idHost -->

							<!-- xsl:variable name="PackagesToHost" select="$PACKAGES/package[@id = $PROFILES/profile/package[(generate-id() = generate-id(key('keyPack',@package-id)[(../@id = $idPoste) or (../@id = $profileHost/depends/@profile-id)]))]/@package-id]" / -->
							<xsl:variable name="PackagesToHost" select="key('PackageFromId', $profileDependsId)" />
							<xsl:variable name="PackagesDepends1" select="key('PackageFromId', $PackagesToHost/depends/@package-id)" />
							<xsl:variable name="PackagesDepends2" select="key('PackageFromId', $PackagesDepends1/depends/@package-id)" />
							<xsl:variable name="PackagesDependants" select="$PackagesDepends1 | $PackagesDepends2" />
							
							<!-- xsl:variable name="nPackagesToHost" select="count($PackagesToHost | $PackagesDependants)" / -->
							<xsl:variable name="AskPackages" select="$PackagesToHost | $PackagesDependants" />
							<xsl:variable name="nPackagesToHost" select="count($AskPackages)" />

							<xsl:variable name="nPackagesInstalled" select="count($CePoste/package[@status = 'Installed'])" />
							
							<xsl:variable name="PackagesNotSynchro" select="(count($CePoste/package[(@status = 'Installed') and not(@id = $AskPackages/@id)]) + count($AskPackages[not(@id = $CePoste/package[@status = 'Installed']/@id)])) > 0" />
							
							<xsl:variable name="PackagesBadVersion" select="$AskPackages[not(@revision = key('RapportRevision', concat($idPoste, ':', @id))/@revision)]" />
							<xsl:variable name="Synchro">
								<xsl:choose>
									<xsl:when test="not($CePoste)"></xsl:when>
									<xsl:when test="$PackagesNotSynchro">NON</xsl:when>
									<xsl:when test="$PackagesBadVersion">Non</xsl:when>
									<xsl:otherwise>OUI</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>

							<xsl:variable name="BGcouleur" >
								<xsl:choose>
									<xsl:when test="$CePoste">
										<!-- Rapport disponible -->
										<xsl:choose>
											<xsl:when test="$PackagesNotSynchro">
												<xsl:text>#FFA500</xsl:text>
											</xsl:when>
											<xsl:when test="$PackagesBadVersion">
												<xsl:text>#ffd07a</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:text>#b3cce5</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<!-- pas de rapport dispo -->
										<xsl:text>ghostwhite</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>

							<xsl:text>Tableau[</xsl:text><xsl:value-of select="position() - 1" /><xsl:text>] = new Array('</xsl:text>
<xsl:text>&lt;tr style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" &gt;&lt;td class="tdlien" style="font-weight: bold;cursor:pointer;" onclick="defHost(&amp;quot;</xsl:text>
<xsl:value-of select="$idPoste" />
<xsl:text>&amp;quot;)"&gt;</xsl:text>
<xsl:value-of select="$idPoste" />
<xsl:text>&lt;/td&gt;</xsl:text>
<xsl:choose>
	<xsl:when test="$CePoste">
		<xsl:choose>
			<xsl:when test="$CePoste/erreur">
				<xsl:text>&lt;td style="font-size:10px;background-color:#FFA500;" &gt;&lt;div style="width:120;color:red;"&gt;' + "</xsl:text>
				<xsl:value-of select="$CePoste/erreur/@str" />
				<xsl:text>" + '&lt;/div&gt;&lt;/td&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&lt;td align="center" style="font-weight: bold;"&gt;</xsl:text>
<xsl:value-of select="$nPackagesInstalled" /><xsl:text> / </xsl:text><xsl:value-of select="$nPackagesToHost" />
				<xsl:text>&lt;/td&gt;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>&lt;td&gt;</xsl:text>
		<xsl:choose>
			<xsl:when test="$CePoste/@logfile">
<xsl:value-of select="$Synchro" /><xsl:text>&lt;/td&gt;&lt;td&gt;</xsl:text>
				<!-- Fichier log disponible -->
				<xsl:text>&lt;span class="tdlien" title="</xsl:text>
<xsl:value-of select="$CePoste/@logfile" />
				<xsl:text>" onclick="javascript:window.open(&amp;quot;index.php?logfile=</xsl:text>
<xsl:value-of select="$CePoste/@logfile" />
				<xsl:text>&amp;quot;, &amp;quot;_blank&amp;quot;);"&gt;</xsl:text>
<xsl:value-of select="$CePoste/@date" /><xsl:text> à </xsl:text><xsl:value-of select="$CePoste/@time" />
				<xsl:text>&lt;/span&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
			<!-- Pas de fichier log disponible -->
<xsl:value-of select="$CePoste/@date" /><xsl:text> à </xsl:text><xsl:value-of select="$CePoste/@time" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>&lt;/td&gt;&lt;td&gt;</xsl:text>
<xsl:value-of select="$CePoste/@mac" />
		<xsl:text>&lt;/td&gt;&lt;td&gt;</xsl:text>
<xsl:value-of select="$CePoste/@ip" />
		<xsl:text>&lt;/td&gt;</xsl:text>
				
	</xsl:when>
	<xsl:otherwise>
		<xsl:text>&lt;td colspan="5" style="font-size:10px;" &gt; Pas de rapport disponible. Attendez qu&amp;#39;un utilisateur s&amp;#39;authentifie sur ce poste. &lt;/td&gt;</xsl:text>
	</xsl:otherwise>
</xsl:choose>
<xsl:text>&lt;/tr&gt; &lt;!--','</xsl:text>

<!-- Clé de tri1 idHost -->
<xsl:value-of select="$idPoste" /><xsl:text>',</xsl:text>
<!-- Clé de tri2 Nb appli ou msg erreur-->
<xsl:choose>
	<xsl:when test="$CePoste/erreur">
		<xsl:text>-1,'</xsl:text>
	</xsl:when>
	<xsl:otherwise>
		<xsl:value-of select="$nPackagesInstalled" /><xsl:text>,'</xsl:text>
	</xsl:otherwise>
</xsl:choose>
<!-- Clé de tri3 Synchro. -->
<xsl:value-of select="$Synchro" /><xsl:text>','</xsl:text>
<!-- Clé de tri4 DateRapport -->
<xsl:value-of select="$CePoste/@datetime" /><xsl:text>','</xsl:text>
<!-- Clé de tri5 add MAC -->
<xsl:value-of select="$CePoste/@mac" /><xsl:text>','</xsl:text>
<!-- Clé de tri6 add IP -->
<xsl:value-of select="$CePoste/@ip" /><xsl:text>',</xsl:text>
<!-- Numéro de la ligne -->
<xsl:value-of select="position() - 1" /><xsl:text>,'--&gt;');&#xa;</xsl:text>

						</xsl:for-each>
					</script>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
