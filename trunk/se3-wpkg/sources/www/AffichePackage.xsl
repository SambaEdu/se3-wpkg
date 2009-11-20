<?xml version="1.0" encoding="iso-8859-1"?>

<!--  Définition d'un package avec affichage de l'état des postes 
		S'applique à profiles.xml
		
		## $Id$ ##
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" encoding="iso-8859-1" />
	<xsl:param name="login" select="''" />
	<xsl:param name="Navigateur" select="'inconnu'" />
	<xsl:param name="Debug" select="false()" />
	<xsl:param name="idPackage" select="''" />
	<xsl:param name="idProfile" select="''" />
	<xsl:param name="Local" select="false()" />
	
	<xsl:key name="rapportFromHostid" match="/wpkg/hosts/host/rapport" use="../@name" />
	<xsl:key name="PackageFromId" match="/wpkg/packages/package" use="@id" />
	<xsl:key name="ProfileFromId" match="/wpkg/profiles/profile" use="@id" />
	
	<xsl:variable name="PROFILES" select="/wpkg/profiles"/>
	<xsl:variable name="PACKAGES" select="/wpkg/packages" />
	<xsl:variable name="nbPackages" select="count($PACKAGES/package)" />
	
	<xsl:variable name="CeProfile" select="key('ProfileFromId', $idProfile)" />
	<xsl:variable name="CePackage" select="key('PackageFromId', $idPackage)" />
	
	<xsl:variable name="isWpkgAdmin" select="key('ProfileFromId', '_TousLesPostes')/@canWrite = '1'"/>
	
	<xsl:variable name="ListProfilesCanRead" select="$PROFILES/profile[not(depends/@profile-id = '_TousLesPostes')]"/>
	<xsl:variable name="ListProfilesCanWrite" select="$ListProfilesCanRead[@canWrite = '1']"/>
	
	<!-- Liste des postes autorisés en lecture par l'utilisateur -->
	<xsl:variable name="ListPostes" select="$PROFILES/profile[depends/@profile-id = '_TousLesPostes']"/>
	<xsl:variable name="ListPostesDeCeProfil" select="$ListPostes[depends/@profile-id = $idProfile]"/>
	<xsl:variable name="canWrite" select="$CeProfile/@canWrite = '1'"/>
	
	<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	
	<xsl:template match="/">
		<xsl:if test="$Debug">
			<pre>
				idProfile=<xsl:value-of select="$idProfile" />
				idPackage=<xsl:value-of select="$idPackage" />
				Navigateur=<xsl:value-of select="$Navigateur" />
				canWrite=<xsl:value-of select="$canWrite" />
				<!-- nbPackages=<xsl:value-of select="$nbPackages" /> -->
			</pre>
		</xsl:if>
		<xsl:element name="div">
			<!-- Sélection d'un autre package -->
			<h3>Application à afficher :
				<select class="SelectH3" id="idPackage" name="idPackage" onchange="defPackage(this.value);">
					<xsl:if test="$idPackage = ''">
						<option class="SelectH3" value="" selected="">Choisir l'application ...</option>
					</xsl:if>
					<xsl:for-each select="$PACKAGES/package">
						<xsl:sort select="translate(@id, $ucletters, $lcletters)" />
						<xsl:choose>
							<xsl:when test="@id = $idPackage">
								<option class="SelectH3" value="{@id}" selected="true()"><xsl:value-of select="@id" /></option>
							</xsl:when>
							<xsl:otherwise>
								<option class="SelectH3" value="{@id}"><xsl:value-of select="@id" /></option>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</select>
			</h3>
			<xsl:if test="not($idPackage = '')">
				<xsl:choose>
					<xsl:when test="$CePackage">
						<div class="TitreNom" ><xsl:value-of select="key('PackageFromId', $idPackage)/@name" /></div>
						<br />
						<xsl:element name="div" >
							<table class="postes">
								<tr>
									<th title="Ce fichier contient la définition de l'application.&#13;Il peut être utilisé pour la réimporter.">Fichier xml de l'appli.</th>
									<th title="Numéro de version de cette application">Version</th>
									<th title="Orde d'installation : priority élevé =&gt; installation en premier.">priorité</th>
									<th title="Faut-il redémarrer le poste, en cas de besoin, après l'installation de cette application ?">reboot</th>
									<th title="Applications nécessaires à l'installation de &apos;{$idPackage}&apos;">dépend de</th>
									<th title="Applications ayant besoin de &apos;{$idPackage}&apos;">requis par</th>
									<xsl:if test="$isWpkgAdmin">
										<th title="Supprimer l'application &apos;{$idPackage}&apos; du serveur">Supprimer</th>
									</xsl:if>
									
								</tr>
								<tr>
									<td align="center" style="font-weight: bold;">
										<a target="_blank">
											<xsl:attribute name="href">
												<xsl:value-of select="concat('index.php?extractAppli=', $idPackage)" />
											</xsl:attribute>
											<xsl:value-of select="$idPackage" />.xml
										</a>							
									</td>
									<td align="right"><xsl:value-of select="$CePackage/@revision" /></td>
									<td align="right"><xsl:value-of select="$CePackage/@priority" /></td>
									<td align="center">
										<xsl:choose>
											<xsl:when test="$CePackage/@reboot = 'true'">Oui</xsl:when>
											<xsl:when test="$CePackage/@reboot = 'false'">Non</xsl:when>
											<xsl:otherwise><xsl:value-of select="$CePackage/@reboot" /></xsl:otherwise>
										</xsl:choose>
									</td>
									<td>
										<xsl:for-each select="$CePackage/depends" >
											<span class="postes">
												<xsl:attribute name="onclick">
													<xsl:value-of select="concat('javascript:defPackage(&quot;', @package-id, '&quot;)')" />
												</xsl:attribute>
												<xsl:value-of select="@package-id" />
											</span>
											<xsl:text> </xsl:text>
										</xsl:for-each>
									</td>
									<td>
										<xsl:for-each select="$PACKAGES/package[ depends/@package-id = $idPackage]" >
											<span class="postes">
												<xsl:attribute name="onclick">
													<xsl:value-of select="concat('javascript:defPackage(&quot;', @id, '&quot;)')" />
												</xsl:attribute>
												<xsl:value-of select="@id" />
											</span>
											<xsl:text> </xsl:text>
										</xsl:for-each>
									</td>
									<xsl:if test="$isWpkgAdmin">
										<td align="center">
											<a style="color:red;text-decoration:line-through;" href="javascript:void(0);" onclick="javascript:document.getElementById('MessageSupprimer').style.display = 'block'; document.getElementById('MessageSupprimer').innerHTML = getHttp( 'index.php?displayDelPackage={$idPackage}', 'html');" title="Supprimer l'application &apos;{$idPackage}&apos; du serveur">
												<xsl:value-of select="$idPackage" />
											</a>
										</td>
									</xsl:if>
								</tr>
							</table>
							<div id="MessageSupprimer" class="MessageSupprimer" >
								<!-- Chargé dynamiquement à l'adresse index.php?displayDelPackage={$idPackage}	-->
							</div>
						</xsl:element>
						<xsl:if test="$CePackage/@configuration">
							<h3>
								<xsl:text>Page de configuration : </xsl:text>
								<a target="_blank">
									<xsl:attribute name="href">
										<xsl:value-of select="$CePackage/@configuration" />
									</xsl:attribute>
									<xsl:value-of select="$CePackage/@configuration" />
								</a>
							</h3>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<!-- L'appli $idPackage a été supprimée -->
						<div class="TitreNom" style="color:#DC143C;" >L'application '<xsl:value-of select="$idPackage" />' a été supprimée du serveur</div>
						<br />
					</xsl:otherwise>
				</xsl:choose>
				<br />
				<table>
					<tr valign="top">
						<td valign="top">
							<h3 style="font-size:medium;">Etat de &apos;<b><xsl:value-of select="$idPackage" /></b>&apos; sur les postes du parc : </h3>
						</td>
						<td>
							<select class="SelectH3" id="idParcPackage" name="idProfile" >
								<xsl:attribute name="onchange">
									<xsl:value-of select="concat('window.ProfileEnCours=this.value;defParcPackage(&quot;', $idPackage,'&quot;);')" />
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
									<xsl:sort select="translate(@id, $ucletters, $lcletters)" />
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
						</td>
						<xsl:if test="$CePackage">
							<xsl:if test="not($idProfile = '')">
								<td>
									<!-- Indication de la demande actuelle -->
									Installation demandée : 
								</td>
								<xsl:choose>
									<xsl:when test="$CeProfile/package[@package-id = $idPackage]">
										<!-- l'install de $idPackage est demandée sur le parc $idProfile -->
										<td>
											<xsl:text>OUI</xsl:text>
										</td>
										<td>
											<div align="center">
												<xsl:attribute name="style"><xsl:value-of select="'background-color:#6699cc;z-index:4;'"/></xsl:attribute>
												<xsl:choose>
													<xsl:when test="$canWrite">
														<xsl:attribute name="class"><xsl:text>CasePackageProfile</xsl:text></xsl:attribute>
														<xsl:attribute name="onclick"><xsl:value-of select="concat('PP(event,&quot;', $idProfile, ':', $idPackage, '&quot;, true);')" /></xsl:attribute>
													</xsl:when>
													<xsl:otherwise>
														<xsl:attribute name="class"><xsl:text>CasePackageProfileReadOnly</xsl:text></xsl:attribute>
														<xsl:text>x</xsl:text>
													</xsl:otherwise>
												</xsl:choose>
											</div>
										</td>
									</xsl:when>
									<xsl:otherwise>
										<!-- l'install de $idPackage n'est pas demandée sur le parc $idProfile -->
										<td>
											<xsl:text>NON</xsl:text>
										</td>
										<td>
											<div align="center">
												<xsl:attribute name="style"><xsl:value-of select="'background-color:#f0f8ff;z-index:3;'"/></xsl:attribute>
												<xsl:choose>
													<xsl:when test="$canWrite">
														<xsl:attribute name="class"><xsl:text>CasePackageProfile</xsl:text></xsl:attribute>
														<xsl:attribute name="onclick"><xsl:value-of select="concat('PP(event,&quot;', $idProfile, ':', $idPackage, '&quot;, true);')" /></xsl:attribute>
													</xsl:when>
													<xsl:otherwise>
														<xsl:attribute name="class"><xsl:text>CasePackageProfileReadOnly</xsl:text></xsl:attribute>
														<xsl:text>x</xsl:text>
													</xsl:otherwise>
												</xsl:choose>
											</div>
										</td>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:if>
					</tr>
				</table>
			</xsl:if>
			<xsl:element name="div">
				<!--xsl:if test="not($idProfile = '') and $CePackage"-->
				<xsl:if test="not($idProfile = '')">
					<!-- Appli à installer à cause des dépendances maxi 2 niveaux de profondeur -->
					<xsl:variable name="ToTalPackageDepends1" select="$PACKAGES/package[depends/@package-id = $idPackage]" />
					<xsl:variable name="ToTalPackageDepends2" select="key('PackageFromId', $ToTalPackageDepends1/depends/@package-id)" />
					<xsl:variable name="ToTalPackageDepends" select="$ToTalPackageDepends1 | $ToTalPackageDepends2" />
					<!-- Appli $idPackage ET Parc $idProfile sélectionnés -->
					<xsl:variable name="nbPostes" select="count($PROFILES/profile[depends/@profile-id = $idProfile])" />
					<div style="font-size:small;" >
						<xsl:choose>
							<xsl:when test="$nbPostes = '0'">
								<xsl:text> 0 poste Windows 2000 ou XP dans le parc </xsl:text>
							</xsl:when>
							<xsl:when test="$nbPostes = '1'">
								<xsl:text> 1 poste Windows 2000 ou XP dans le parc </xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$nbPostes" /><xsl:text> poste(s) Windows 2000 ou XP dans le parc </xsl:text>
							</xsl:otherwise>
						</xsl:choose>
						<b><xsl:value-of select="$idProfile" /></b><br></br> 
					</div>
					<!-- Liste des poste concernés par ce profile (=Parc) -->
					<div id="divTableau">
						<table class="postes">
							<thead id="headTableau">
								<tr>
									<th style="cursor:ne-resize;" onclick="tri(1,event);">Poste</th>
									<th style="cursor:ne-resize;" onclick="tri(2,event);" title="&apos;Installée&apos; ou &apos;Non installée&apos;.   En rouge si l'état ne correspond pas à la demande">
										<xsl:choose>
											<xsl:when test="$idPackage = ''">Etat de ?</xsl:when>
											<xsl:otherwise>Etat de <xsl:value-of select="$idPackage" /></xsl:otherwise>
										</xsl:choose>
									</th>
									<th style="cursor:ne-resize;" onclick="tri(3,event);">Version</th>
									<th style="cursor:ne-resize;" onclick="tri(4,event);">Reboot</th>
									<th style="cursor:ne-resize;" onclick="tri(5,event);" title="Cliquer sur la date du rapport pour voir le fichier de log d'exécution de ce poste">Date du dernier rapport</th>
									<th style="cursor:ne-resize;" onclick="tri(6,event);">Adresse MAC</th>
									<th style="cursor:ne-resize;" onclick="tri(7,event);">Adresse IP</th>
									<xsl:if test="$CePackage">
										<th style="cursor:ne-resize;" onclick="tri(8,event);" title="Installer &apos;{$idPackage}&apos; uniquement sur ce poste">Installer sur ce poste</th>
									</xsl:if>
								</tr>
							</thead>

							<tbody id="bodyTableau">
							</tbody>
						</table>
					</div>
					<script id="ScriptTableau" type="text/javascript"><xsl:text>Tableau = new Array();&#xa;</xsl:text>
						<xsl:for-each select="$ListPostesDeCeProfil" >
							<xsl:variable name="idPoste" select="@id"/>
							<xsl:variable name="CePoste" select="key('rapportFromHostid', $idPoste)"/>
							<xsl:variable name="CePackageDuPoste" select="$CePoste/package[@id = $idPackage]"/>
							<xsl:variable name="profileDeCetHost" select="key('ProfileFromId', $idPoste)"/>
							<!-- Liste des profils dont dépend l'Host -->
							<xsl:variable name="ToTalPackProfile" select="key('ProfileFromId', ($profileDeCetHost/depends/@profile-id) | $idPoste)/package/@package-id" />
							<xsl:variable name="ToTalPackage" select="$ToTalPackageDepends[@id = $ToTalPackProfile]" />
							<!-- xsl:text>// </xsl:text><xsl:value-of select="concat('ToTalPackageDepends:', count($ToTalPackageDepends), 'ToTalPackProfile:', count($ToTalPackProfile), ', ToTalPackage:', count($ToTalPackage))" /><xsl:text>&#xa;</xsl:text -->

							<xsl:variable name="requestInstallHostOnly" select="count($profileDeCetHost/package[@package-id = $idPackage]) > 0" />
							<xsl:variable name="isInstallRequested" select="count($ToTalPackage) + count($ToTalPackProfile[ . = $idPackage]) > 0"/>
							<xsl:variable name="showCaseInstallHostOnly" select="$requestInstallHostOnly or not($isInstallRequested)" />
							
							<xsl:variable name="status" >
								<xsl:if test="$CePoste">
									<xsl:variable name="packageEnCours" select="$CePoste/package[@id = $idPackage]" />
									<xsl:choose>
										<xsl:when test="$idPackage = ''"></xsl:when>
										<xsl:when test="not($packageEnCours/@status)">
											<xsl:text>Inconnu</xsl:text>
										</xsl:when>
										<xsl:when test="$packageEnCours/@status = 'Installed'">
											<xsl:text>Installé</xsl:text>
										</xsl:when>
										<xsl:when test="$packageEnCours/@status = 'Not Installed'">
											<xsl:text>Non installé</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$packageEnCours/@status" />
										</xsl:otherwise>
									</xsl:choose>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="BGcouleur" >
								<xsl:choose>
									<xsl:when test="$status = 'Inconnu'">
										<!-- appli au status inconnu -->
										<xsl:text>ghostwhite</xsl:text>
									</xsl:when>
									<xsl:when test="$status = 'Non installé'">
										<xsl:choose>
											<xsl:when test="not($isInstallRequested)">
												<!-- appli NON installée avec demande identique bleu grisclair -->
												<xsl:text>#dee2e5</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<!-- appli non installée  #FF7F50-->
												<xsl:text>#FFA500</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="$status = 'Installé'">
										<xsl:choose>
											<xsl:when test="$isInstallRequested">
												<xsl:choose>
													<xsl:when test="$CePackageDuPoste/@revision = $CePackage/@revision">
														<!-- N° de version OK -->
														<xsl:text>#b3cce5</xsl:text>
													</xsl:when>
													<xsl:otherwise>
														<!-- appli installée dans une autre version -->
														<xsl:text>#ffd07a</xsl:text>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:when>
											<xsl:otherwise>
												<!-- appli installée -->
												<xsl:text>#FFA500</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<!-- autre cas ? -->
										<xsl:text>ghostwhite</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<xsl:text>Tableau[</xsl:text><xsl:value-of select="position() - 1" /><xsl:text>] = new Array('</xsl:text>
<xsl:text>&lt;tr style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" &gt;</xsl:text>
	<xsl:text>&lt;td class="tdlien" style="font-weight: bold;cursor:pointer;" onclick="defHost(&amp;quot;</xsl:text><xsl:value-of select="$idPoste" /><xsl:text>&amp;quot;)"&gt;</xsl:text>
		<xsl:value-of select="$idPoste" />
	<xsl:text>&lt;/td&gt;</xsl:text>
	<xsl:choose>
		<xsl:when test="$CePoste">
			<!-- Si un rapport existe pour ce poste -->
			
			<xsl:variable name="reboot" select="$CePackageDuPoste/@reboot" />
			<xsl:text>&lt;td align="center" style="font-weight: bold;"&gt;</xsl:text>
			<xsl:value-of select="$status" />
			<xsl:text>&lt;/td&gt;</xsl:text>
			<xsl:text>&lt;td align="right"&gt;</xsl:text>
			<xsl:choose>
				<xsl:when test="$CePackageDuPoste/@revision = $CePackage/@revision">
					<xsl:value-of select="$CePackageDuPoste/@revision" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>&lt;font color="red" style="font-weight:bold;"&gt;</xsl:text>
					<xsl:value-of select="$CePackageDuPoste/@revision" />
					<xsl:text>&lt;/font&gt;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:text>&lt;/td&gt;</xsl:text>
			
			<xsl:text>&lt;td align="center"&gt;</xsl:text>
			<xsl:choose>
				<xsl:when test="$reboot = 'false'">
					<xsl:text>Non</xsl:text>
				</xsl:when>
				<xsl:when test="$reboot = 'true'">
					<xsl:text>Oui</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$reboot" />
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>&lt;/td&gt;</xsl:text>
			
			<xsl:choose>
				<xsl:when test="$CePoste/@logfile">
					<!-- Fichier log disponible -->
					<xsl:text>&lt;td&gt;&lt;span class="tdlien" title="</xsl:text>
						<xsl:value-of select="$CePoste/@logfile" />
						<xsl:text>" onclick="javascript:window.open(&amp;quot;index.php?logfile=</xsl:text>
						<xsl:value-of select="$CePoste/@logfile" />
						<xsl:text>&amp;quot;, &amp;quot;_blank&amp;quot;);"&gt;</xsl:text>
						<xsl:value-of select="$CePoste/@date" /><xsl:text> à </xsl:text><xsl:value-of select="$CePoste/@time" />
						<xsl:text>&lt;/span&gt;</xsl:text>
					<xsl:text>&lt;/td&gt;</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>&lt;td title="Pas de fichier de log disponible."&gt;</xsl:text>
					<xsl:value-of select="$CePoste/@date" /><xsl:text> à </xsl:text><xsl:value-of select="$CePoste/@time" />
					<xsl:text>&lt;/td&gt;</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>&lt;td&gt;</xsl:text>
			<xsl:value-of select="$CePoste/@mac" />
			<xsl:text>&lt;/td&gt;</xsl:text>
			<xsl:text>&lt;td&gt;</xsl:text>
			<xsl:value-of select="$CePoste/@ip" />
			<xsl:text>&lt;/td&gt;</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>&lt;td colspan="6" style="font-size:10px;" &gt; Pas de rapport disponible. Attendez qu&amp;#39;un utilisateur s&amp;#39;authentifie sur ce poste. &lt;/td&gt;</xsl:text>				
		</xsl:otherwise>
	</xsl:choose>
	
	<xsl:if test="$CePackage">
		<xsl:text>&lt;td align="center"&gt;</xsl:text>
			<xsl:if test="not($idPackage='')">
				<xsl:text>&lt;div class="</xsl:text>
				<xsl:choose>
					<xsl:when test="$canWrite" ><xsl:text>CasePackageProfile</xsl:text></xsl:when>
					<xsl:otherwise><xsl:text>CasePackageProfileReadOnly</xsl:text></xsl:otherwise>
				</xsl:choose>
				<xsl:text>" style="position:relative;</xsl:text>
				<xsl:choose>
					<xsl:when test="$requestInstallHostOnly">
						<xsl:text>background-color:#6699cc;z-index:4;</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>background-color:#f0f8ff;z-index:3;</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>" </xsl:text>
				<xsl:choose>
					<xsl:when test="$canWrite" >
						<xsl:text>onclick="PP(event,&amp;quot;</xsl:text>
						<xsl:value-of select="$idPoste" /><xsl:text>:</xsl:text><xsl:value-of select="$idPackage" />
						<xsl:text>&amp;quot;,true);"&gt;</xsl:text>
					</xsl:when>
					<xsl:otherwise><xsl:text>&gt;x</xsl:text></xsl:otherwise>
				</xsl:choose>
				<xsl:text>&lt;/div&gt;</xsl:text>
			</xsl:if>
		<xsl:text>&lt;/td&gt;</xsl:text>
	</xsl:if>
	<xsl:text>&lt;/tr&gt; &lt;!--','</xsl:text>
<!-- Clé de tri1 idPoste-->
<xsl:value-of select="$idPoste" /><xsl:text>','</xsl:text>
<xsl:choose>
	<xsl:when test="$CePoste">
		<!-- Clé de tri2 Etat appli -->
		<xsl:value-of select="$status" /><xsl:text>',</xsl:text>
		<!-- Clé de tri3 Revision (numérique) -->
		<xsl:choose>
			<xsl:when test="$CePackageDuPoste/@revision">
				<xsl:value-of select="$CePackageDuPoste/@revision" />
			</xsl:when>
			<xsl:otherwise>''</xsl:otherwise>
		</xsl:choose><xsl:text>,'</xsl:text>
		<!-- Clé de tri4 reboot -->
		<xsl:value-of select="$CePackageDuPoste/@reboot" /><xsl:text>','</xsl:text>
		<!-- Clé de tri5 DateRapport -->
		<xsl:value-of select="$CePoste/@datetime" /><xsl:text>','</xsl:text>
		<!-- Clé de tri6 add MAC -->
		<xsl:value-of select="$CePoste/@mac" /><xsl:text>','</xsl:text>
		<!-- Clé de tri7 add Ip-->
		<xsl:value-of select="$CePoste/@ip" /><xsl:text>',</xsl:text>
	</xsl:when>
	<xsl:otherwise>
		<xsl:text>',0,'','','','',</xsl:text>
	</xsl:otherwise>
</xsl:choose>
<xsl:if test="$CePackage">
	<!-- Clé de tri8 install host only-->
	<xsl:text>'</xsl:text><xsl:value-of select="$requestInstallHostOnly" /><xsl:text>',</xsl:text>
</xsl:if>
<!-- Numéro de la ligne -->
<xsl:value-of select="position() - 1" /><xsl:text>,'--&gt;');&#xa;</xsl:text>

						</xsl:for-each>
					</script>
				</xsl:if>
			</xsl:element>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
