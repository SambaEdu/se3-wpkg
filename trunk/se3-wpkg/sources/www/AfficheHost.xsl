<?xml version="1.0" encoding="iso-8859-1"?>

<!--  Affichage détaillé de l'état d'un poste
		S'applique à wpkg.xml
		
		## $Id$ ##
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:key name = "keyPack" match = "package" use = "@package-id" />
	

	<xsl:output method="html" encoding="iso-8859-1" />
	<xsl:param name="Navigateur" select="'inconnu'" />
	<xsl:param name="Debug" select="false()" />
	<xsl:param name="Local" select="false()" />
	<xsl:param name="idHost" select="''" />

	<xsl:variable name="PROFILES" select="/wpkg/profiles"/>
	<xsl:variable name="PACKAGES" select="/wpkg/packages"/>
	<xsl:variable name="HOSTS" select="/wpkg/hosts"/>
	
	<!-- Liste des postes autorisés en lecture par l'utilisateur -->
	<xsl:variable name="ListPostes" select="$PROFILES/profile[depends/@profile-id = '_TousLesPostes']"/>
	<xsl:variable name="RapportDuPoste" select="$HOSTS/host[@name = $idHost]/rapport"/>
	
	<!-- Profile à partir de l'@id -->
	<xsl:key name="ProfileFromHostid" match="/wpkg/profiles/profile" use="@id" />
	
	<!-- Package à partir de l'@id -->
	<xsl:key name="PackageFromId" match="/wpkg/packages/package" use="@id" />
	<xsl:key name="RapportRevision" match="/wpkg/hosts/host/rapport/package" use="concat(../@id, ':', @id)" />
	
	<xsl:variable name="profileHost" select="key('ProfileFromHostid', $idHost)" />
	<xsl:variable name="canWrite" select="$profileHost[@canWrite = '1']"/>
	<!-- Nombre de packages à installer demandés pour idHost -->
	<!-- <xsl:variable name="DemandePackages" select="$PROFILES/profile/package[(generate-id() = generate-id(key('keyPack',@package-id)[(../@id = $idHost) or (../@id = $profileHost/depends/@profile-id)]))]" /> -->
	<xsl:variable name="PackagesFromRapport" select="$RapportDuPoste/package" />
	<xsl:variable name="PackagesNotInRapport" select="$PACKAGES/package[not(@id = $RapportDuPoste/package/@id)]" />
	<!-- Liste des profils dont dépend l'Host -->
	<!-- xsl:key name="profileDependant" match="/wpkg/profiles/profile" use="depends/@profile-id" / -->
	
	<xsl:variable name="ToTalProfile" select="key('ProfileFromHostid', $profileHost/depends/@profile-id) | $profileHost" />
	<!-- Package dont l'install est demandée -->
	<xsl:variable name="DemandPackages" select="key('PackageFromId', $ToTalProfile/package/@package-id)" />
    <!-- Packages à installer à cause des dépendances de packages maxi 3 niveaux de profondeur -->
	<xsl:variable name="PackageDepends1" select="key('PackageFromId', $DemandPackages/depends/@package-id)" />
	<xsl:variable name="PackageDepends2" select="key('PackageFromId', $PackageDepends1/depends/@package-id)" />
	<xsl:variable name="PackageDepends3" select="key('PackageFromId', $PackageDepends2/depends/@package-id)" />
	<xsl:variable name="ToTalPackageDepends" select="$PackageDepends1 | $PackageDepends2 | PackageDepends3" />
  
	<xsl:variable name="AskPackages" select="$DemandPackages | $ToTalPackageDepends" />
	<xsl:variable name="nDemandPackages" select="count($AskPackages)" />
  
	<xsl:variable name="PackagesNotSynchro" select="(count($PackagesFromRapport[(@status = 'Installed') and not(@id = $AskPackages/@id)]) + count($AskPackages[not(@id = $PackagesFromRapport[@status = 'Installed']/@id)])) > 0" />
	<xsl:variable name="PackagesBadVersion" select="$AskPackages[not(@revision = key('RapportRevision', concat($idHost, ':', @id))/@revision)]" />
	<xsl:variable name="Synchro">
		<xsl:choose>
			<xsl:when test="not($PackagesFromRapport)">-2</xsl:when>
			<xsl:when test="$PackagesNotSynchro">-1</xsl:when>
			<xsl:when test="$PackagesBadVersion">0</xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	
	<xsl:template match="/">
		<xsl:comment>
			<xsl:text> ToTalProfile = </xsl:text>
			<xsl:for-each select="$ToTalProfile">
				<xsl:value-of select="concat(@id, ' ')" /> 
			</xsl:for-each>
			<xsl:text>
DemandPackages = </xsl:text>
			<xsl:for-each select="$DemandPackages">
				<xsl:value-of select="concat(@id, ' ')" /> 
			</xsl:for-each>
		</xsl:comment>
		<xsl:if test="$Debug">
			<pre>
				idHost=<xsl:value-of select="$idHost" />
				Navigateur=<xsl:value-of select="$Navigateur" />
			</pre>
		</xsl:if>
		<xsl:element name="div">
			<!-- Sélection d'un autre poste -->
			<h3>Poste à afficher : 
				<select class="SelectH3" id="idHost" name="idHost" >
					<xsl:attribute name="onchange">
						<xsl:value-of select="'defHost(this.value);'" />
					</xsl:attribute>
					<xsl:if test="$idHost = ''">
						<option value="''" selected="true()"><xsl:value-of select="'Choisir le poste...'" /></option>
					</xsl:if>
					<xsl:for-each select="$ListPostes">
						<xsl:sort select="translate(@id, $ucletters, $lcletters)" />
						<xsl:choose>
							<xsl:when test="@id = $idHost">
								<option value="{@id}" selected="true()"><xsl:value-of select="@id" /></option>
							</xsl:when>
							<xsl:otherwise>
								<option value="{@id}"><xsl:value-of select="@id" /></option>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</select>
 			</h3>
		</xsl:element>
		<xsl:choose>
			<xsl:when test="$idHost = ''">
				<!-- Pas de poste sélectionné -->
			</xsl:when>
			<xsl:otherwise>
				
				<div class="TitreNom" ><xsl:value-of select="$idHost" /></div>
				<br />
				<xsl:variable name="nInstalled" select="count($RapportDuPoste/package[@status = 'Installed'])"/>
				<xsl:element name="div" >
					<table class="postes">
						<tr>
							<th>Poste</th>
							<th title="Nbre d'appli. installées / Nbre d'appli. souhaitées" >Nbre d'appli.</th>
							<th title="Cliquer sur la date du rapport pour voir le fichier de log d'exécution de ce poste">Date du dernier rapport</th>
							<th>Adresse MAC</th>
							<th>Adresse IP</th>
							<th>Appartient aux parcs</th>
							<th title="(re)démarrer le poste par le réseau">(Re)démarrer</th>
						</tr>
						<tr>
							<td style="font-weight: bold;"><xsl:value-of select="$idHost" /></td>
							<xsl:choose>
								<xsl:when test="$RapportDuPoste">
									<!-- Si un rapport existe pour ce poste -->
									<xsl:choose>
										<xsl:when test="$RapportDuPoste/erreur">
											<td style="font-size:10px;background-color:#FFA500;" ><xsl:value-of select="$RapportDuPoste/erreur/@str" /></td>
										</xsl:when>
										<xsl:when test="($Synchro = '-2') or ($Synchro = '-1')">
											<td style="background-color:#FFA500;font-weight: bold;" align="center">
												<xsl:value-of select="$nInstalled" />
												<xsl:text> / </xsl:text>
												<xsl:value-of select="$nDemandPackages" />
											</td>
										</xsl:when>
										<xsl:when test="$Synchro = '0'">
											<!-- Bad version -->
											<td style="background-color:#ffd07a;font-weight: bold;" align="center">
												<xsl:value-of select="$nInstalled" />
												<xsl:text> / </xsl:text>
												<xsl:value-of select="$nDemandPackages" />
											</td>
										</xsl:when>
										<xsl:otherwise>
											<td align="center" style="font-weight: bold;">
												<xsl:value-of select="$nInstalled" />
												<xsl:text> / </xsl:text>
												<xsl:value-of select="$nDemandPackages" />
											</td>
										</xsl:otherwise>
									</xsl:choose>
									<xsl:choose>
										<xsl:when test="$RapportDuPoste/@logfile">
											<!-- Fichier log disponible -->
											<td>
												<span class="tdlien" title="{$RapportDuPoste/@logfile}" onclick="javascript:window.open(&apos;index.php?logfile={$RapportDuPoste/@logfile}&apos;, &apos;_blank&apos;);">
													<xsl:value-of select="$RapportDuPoste/@date" /> à <xsl:value-of select="$RapportDuPoste/@time" />
												</span>
											</td>
										</xsl:when>
										<xsl:otherwise>
											<td title="Pas de fichier de log disponible.">
												<xsl:value-of select="$RapportDuPoste/@date" /> à <xsl:value-of select="$RapportDuPoste/@time" />
											</td>
										</xsl:otherwise>
									</xsl:choose>
									<td><xsl:value-of select="$RapportDuPoste/@mac" /></td>
									<xsl:choose>
										<xsl:when test="$RapportDuPoste/@ip and $RapportDuPoste/@mask">
											<td title="{concat('Masque : ', $RapportDuPoste/@mask)}">
												<xsl:value-of select="$RapportDuPoste/@ip" />
											</td>
										</xsl:when>
										<xsl:otherwise>
											<td><xsl:value-of select="$RapportDuPoste/@ip" /></td>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<td colspan="4" style="font-size:10px;" ><xsl:text> Pas de rapport disponible. Attendez qu'un utilisateur s'authentifie sur ce poste. </xsl:text></td>
								</xsl:otherwise>
							</xsl:choose>
							<td>
								<!-- Liste des Parcs auxquels appartient $idHost -->
								<xsl:for-each select="$profileHost/depends[not(@profile-id = '_TousLesPostes')]">
									<span class="postes">
										<xsl:attribute name="onclick">
											<xsl:value-of select="concat('javascript:defProfile(&quot;', @profile-id, '&quot;)')" />
										</xsl:attribute>
										<xsl:value-of select="@profile-id" />
									</span>
									<xsl:choose>
										<xsl:when test="not(position()=last())">
											<xsl:text>, </xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>.</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</td>
							<td valign="top" align="center">
								<xsl:if test="$RapportDuPoste/@ip and $RapportDuPoste/@mask">
									<table border="0"><tr style="border:0;">
									<td style="border:0;"><button style="font-size:smaller;" title="Démarrer '{$idHost}'" onclick="startHost('{$idHost}', '{$RapportDuPoste/@ip}', '{$RapportDuPoste/@mask}' , '{$RapportDuPoste/@mac}' );">(Re)Boot !</button></td>
									<xsl:if test="key('RapportRevision', concat($idHost, ':consoleWpkg'))/@status = 'Installed'">
										<td id="consoleWpkg" style="border:0;"/>
										<script id="initConsoleWpkg" type="text/javascript" >
											<xsl:value-of select="concat('ipHost=&#34;', $RapportDuPoste/@ip, '&#34;;')" />
<xsl:text>
onclickConsoleWpkg="javascript:window.open(&amp;apos;consoleWpkg.php?clientIp=</xsl:text><xsl:value-of select="$RapportDuPoste/@ip" /><xsl:text>&amp;apos;, &amp;apos;_blank&amp;apos;);";
document.getElementById("consoleWpkg").innerHTML = "&lt;img title='Console WPKG' src='img/consoleWpkg.png' style='cursor:pointer;' onclick='" + onclickConsoleWpkg + "');'/&gt;";
</xsl:text>
										</script>
									</xsl:if>
									</tr></table>
								</xsl:if>
							</td>
						</tr>
					</table>
				</xsl:element>
				<div id="posteparam">
					<a style="font-size:small;" onclick="posteini('{$idHost}');">Définir la valeur des options passées au client wpkg</a>
					<!--font size="2">
						<button style="font-size:x-small;" title="Infos de déboggage" onclick="posteini('{$idHost}', 'debug', '-' );">/debug</button>Pour avoir des log plus détaillées. 
						<button style="font-size:x-small;" title="Déboggage temps réel" onclick="posteini('{$idHost}', 'logdebug', '-' );">/logdebug</button>Met à jour le fichier de log sur le serveur en temps réel. 
						<button style="font-size:x-small;" title="Vérifier l'état" onclick="posteini('{$idHost}', 'force', '-' );">/force</button> Vérifie l'état installé ou non des applis.<br/>
						<button title="Changer pour ce poste" onclick="posteini('{$idHost}', 'DELETE', '-' );">Supprimer</button> Supprime les options particulière à ce poste.
					</font -->
				</div>
				<xsl:element name="div" >
					<!-- Etat des applications sur ce poste -->
					<xsl:if test="$RapportDuPoste">
						<!-- Un rapport est disponible pour ce poste -->
						<xsl:variable name="nAppli" select="count($RapportDuPoste/package)"/>
						<xsl:variable name="profileDeCetHost" select="key('ProfileFromHostid', $idHost)"/>

						<h3>Applications sur le poste '<b><xsl:value-of select="$idHost" /></b>'.</h3>
						<div id="divTableau">
							<table class="postes">
								<thead id="headTableau">
									<!-- Tableau des applis installées sur ce poste -->
									<tr>
										<th style="cursor:ne-resize;" onclick="tri(1,event);" >Application</th>
										<th style="cursor:ne-resize;" onclick="tri(2,event);" title="&apos;Installée&apos; ou &apos;Non installée&apos;.   En rouge si l'état ne correspond pas à la demande">Etat</th>
										<th style="cursor:ne-resize;" onclick="tri(3,event);" >Version</th>
										<th style="cursor:ne-resize;" onclick="tri(4,event);" title="L'installation nécessite-t-elle un reboot ?">Reboot</th>
										<th style="cursor:ne-resize;" onclick="tri(5,event);" title="Parcs, poste ou appli. à l'origine de la demande d'installation">Install. demandée pour</th>
										<th style="cursor:ne-resize;" onclick="tri(6,event);" title="Installation d'une application uniquement sur &apos;{$idHost}&apos;">Installer sur ce poste</th>
									</tr>
								</thead>

								<tbody id="bodyTableau">
								</tbody>
							</table>
						</div>
						<script id="ScriptTableau" type="text/javascript"><xsl:text>Tableau = new Array();&#xa;</xsl:text>
							<xsl:for-each select="$PackagesFromRapport | $PackagesNotInRapport" >
								<xsl:sort select="translate(@id, $ucletters, $lcletters)" />
								<xsl:variable name="idPackage" select="@id"/>
								<xsl:variable name="Package" select="key('PackageFromId', $idPackage)"/>
								<xsl:variable name="profilsImplyPackageHost" >
									<xsl:call-template name="profilsImplyPackageHost" >
										<xsl:with-param name="tmpProfile" select="$profileDeCetHost" />
										<xsl:with-param name="tmpPackage" select="$idPackage" />
									</xsl:call-template>
									<xsl:call-template name="packagesImplyPackage" >
										<xsl:with-param name="tmpPackage" select="$idPackage" />
										<xsl:with-param name="withLink" select="true()" />
									</xsl:call-template>
								</xsl:variable>
								<xsl:variable name="requestInstallHostOnly" select="count($profileDeCetHost/package[@package-id = $idPackage])" />
								<xsl:variable name="isInstallRequested" select="(not($profilsImplyPackageHost = '')) or ($requestInstallHostOnly > 0)"/>
								<xsl:variable name="status" >
									<xsl:choose>
										<xsl:when test="@status = 'Installed'">
											<xsl:text>Installé</xsl:text>
										</xsl:when>
										<xsl:when test="@status = 'Not Installed'">
											<xsl:text>Non installé</xsl:text>
										</xsl:when>
										<xsl:when test="not(@status)">
											<xsl:text>Inconnu</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="@status" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="reboot" >
									<xsl:choose>
										<xsl:when test="not(@status)"></xsl:when>
										<xsl:when test="@reboot = 'false'">
											<xsl:text>Non</xsl:text>
										</xsl:when>
										<xsl:when test="@reboot = 'true'">
											<xsl:text>Oui</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="@reboot" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="revision" >
									<xsl:choose>
										<xsl:when test="not(@status)"></xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="@revision" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="BGcouleur" >
									<xsl:choose>
										<xsl:when test="not(@status)">
											<!-- appli au status inconnu -->
											<xsl:text>ghostwhite</xsl:text>
										</xsl:when>
										<xsl:when test="(not(@status = 'Installed')) and (not($isInstallRequested))">
											<!-- appli NON installée avec demande identique bleu grisclair -->
											<xsl:text>#dee2e5</xsl:text>
										</xsl:when>
										<xsl:when test="(@status = 'Installed') and ($isInstallRequested)">
											<!-- appli installée avec demande identique -->
											<xsl:choose>
												<xsl:when test="@revision = $Package/@revision">
													<!-- N° de version OK -->
													<xsl:text>#b3cce5</xsl:text>
												</xsl:when>
												<xsl:otherwise>
													<!-- appli installée dans une autre version -->
													<xsl:text>#ffd07a</xsl:text>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:when test="@status = 'Installed'">
											<!-- appli installée avec install non demandée -->
											<xsl:text>#FFA500</xsl:text>
										</xsl:when>
										<xsl:when test="@status = 'Not Installed'">
											<!-- appli non installée et install demandée #FF7F50-->
											<xsl:text>#FFA500</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<!-- autre cas ? -->
											<xsl:text>ghostwhite</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>





								<xsl:text>Tableau[</xsl:text><xsl:value-of select="position() - 1" /><xsl:text>] = new Array('</xsl:text>
<xsl:text>&lt;tr style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" />
<xsl:text>;" &gt; &lt;td class="tdlien" title="' + "</xsl:text>
<xsl:value-of select="concat($Package/@name, ' (Rev:', $Package/@revision,')')" />
<xsl:text>" + '" style="font-weight: bold;cursor:pointer;" onclick="defPackage(&amp;quot;</xsl:text>
	<xsl:value-of select="@id" /><xsl:text>&amp;quot;);"&gt;</xsl:text>
	<xsl:value-of select="@id" /><xsl:text>&lt;/td&gt; &lt;td align="center" &gt;</xsl:text>
		<xsl:value-of select="$status" />
	<xsl:text>&lt;/td&gt; &lt;td align="right" &gt;</xsl:text>
	<xsl:choose>
		<xsl:when test="@revision = key('PackageFromId', $idPackage)/@revision">
			<xsl:value-of select="$revision" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>&lt;font color="red" style="font-weight:bold;"&gt;</xsl:text>
			<xsl:value-of select="$revision" />
			<xsl:text>&lt;/font&gt;</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
	
	<xsl:text>&lt;/td&gt; &lt;td align="center" &gt;</xsl:text>
	<xsl:value-of select="$reboot" />
	<xsl:text>&lt;/td&gt; &lt;td &gt; </xsl:text><xsl:copy-of select="$profilsImplyPackageHost" />
	<xsl:text>&lt;/td&gt; &lt;td align="center" &gt;</xsl:text>
	<xsl:if test="$Package">
		<xsl:text> &lt;div class="</xsl:text>
		<xsl:choose>
			<xsl:when test="$canWrite" >
				<xsl:text>CasePackageProfile</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>CasePackageProfileReadOnly</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>" style="</xsl:text>
		<xsl:choose>
			<xsl:when test="$requestInstallHostOnly">
				<xsl:value-of select="'position:relative;background-color:#6699cc;z-index:4;'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'position:relative;background-color:#f0f8ff;z-index:3;'"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>" </xsl:text>
		<xsl:if test="$canWrite" >
			<xsl:text>onclick="PP(event,&amp;quot;</xsl:text>
			<xsl:value-of select="concat($idHost, ':', @id)" />
			<xsl:text>&amp;quot;,true);"</xsl:text>
		</xsl:if>
		<xsl:text>&gt; </xsl:text>
		<xsl:if test="not($canWrite)" >
			<xsl:text>x</xsl:text>
		</xsl:if>
		<xsl:text>&lt;/div&gt;</xsl:text>
	</xsl:if>
	<xsl:text> &lt;/td&gt;&lt;/tr&gt; &lt;!--','</xsl:text>
<!-- Clé de tri1 idPackage-->
<xsl:value-of select="translate(@id, $ucletters, $lcletters)" /><xsl:text>','</xsl:text>
<!-- Clé de tri2 Etat -->
<xsl:value-of select="$status" /><xsl:text>',</xsl:text>
<!-- Clé de tri3 Revision (numérique) -->
<xsl:choose><xsl:when test="$revision = ''">0</xsl:when><xsl:otherwise><xsl:value-of select="0 + $revision" /></xsl:otherwise></xsl:choose><xsl:text>,'</xsl:text>
<!-- Clé de tri4 reboot -->
<xsl:value-of select="$reboot" /><xsl:text>','</xsl:text>
<!-- Clé de tri5 install. demandée par -->
<xsl:value-of select="string($profilsImplyPackageHost)" /><xsl:text>','</xsl:text>
<!-- Clé de tri6 install host only-->
<xsl:value-of select="$requestInstallHostOnly" /><xsl:text>',</xsl:text>
<!-- Numéro de la ligne -->
<xsl:value-of select="position() - 1" /><xsl:text>,'--&gt;');&#xa;</xsl:text>
							</xsl:for-each>
						</script>
						
					</xsl:if>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="profilsImplyPackageHost" >
		<!-- Retourne les profils qui ont réclamé l'installation de ce package sur cet host -->
		<xsl:param name="tmpProfile" /> <!-- initialement : profile du poste, puis profils dont dépend l'host -->
		<xsl:param name="tmpPackage" /> <!-- Id de l'appli cherchée -->
		<xsl:param name="withLink" select="false()"/> <!-- Faut-il ajouter un lien vers le profile (Non si idProfile=idHost) -->
		<xsl:if test="$tmpProfile/package[@package-id = $tmpPackage]">
			<!-- Ce profile réclame l'installation de l'appli -->
			<xsl:choose>
				<xsl:when test="$withLink">
					<xsl:text>&lt;span class="postes" title="Parc &amp;#39;</xsl:text><xsl:value-of select="$tmpProfile/@id" /><xsl:text>&amp;#39;" onclick="defProfile(&amp;quot;</xsl:text><xsl:value-of select="$tmpProfile/@id" /><xsl:text>&amp;quot;);" &gt;</xsl:text>
						<xsl:value-of select="$tmpProfile/@id" />
					<xsl:text>&lt;/span&gt;</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$tmpProfile/@id" />
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text> </xsl:text>
		</xsl:if>
		<xsl:for-each select="$tmpProfile/depends[@profile-id]">
			<xsl:variable name="profilSuivant" select="@profile-id"/>
			<xsl:call-template name = "profilsImplyPackageHost" >
				<xsl:with-param name="tmpProfile" select="key('ProfileFromHostid', $profilSuivant)" />
				<xsl:with-param name="tmpPackage" select="$tmpPackage" />
				<xsl:with-param name="withLink" select="true()" />
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="packagesImplyPackage" >
		<!-- Retourne les packages qui ont réclamé l'installation de ce package sur cet host (dépendances de packages) -->
		<xsl:param name="tmpPackage" /> <!-- Id de l'appli cherchée -->
		<xsl:param name="withLink" select="false()"/> <!-- Faut-il ajouter un lien vers le package  -->
		<xsl:variable name="packagesImply" select="$ToTalPackageDepends[@id = $tmpPackage]" />
		<xsl:if test="$packagesImply">
			<xsl:choose>
				<xsl:when test="$withLink">
					<xsl:for-each select="($AskPackages)[$tmpPackage = depends/@package-id]">
						<xsl:text>&lt;span class="spanAppDepends" title="Application &amp;#39;</xsl:text><xsl:value-of select="@id" /><xsl:text>&amp;#39;" onclick="defPackage(&amp;quot;</xsl:text><xsl:value-of select="@id" /><xsl:text>&amp;quot;);" &gt;</xsl:text>
							<xsl:value-of select="@id" />
						<xsl:text>&lt;/span&gt; </xsl:text>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="($AskPackages)[$tmpPackage = depends/@package-id]">
						<xsl:value-of select="@id" />
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>
