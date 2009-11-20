<?xml version="1.0" encoding="iso-8859-1"?>
<!-- < ?xml version="1.0" encoding="windows-1252"? > -->

<!--  Affichage de la page d'ajout de package unique ou du tableau des MAJ des xml à partir du forum

	## $Id$ ##
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" encoding="iso-8859-1" />
	<!-- passage de paramètres à partir du javascript (admin.html) -->
	<xsl:param name="Navigateur" ><xsl:text>inconnu</xsl:text></xsl:param>
	<xsl:param name="wpkgAdmin" ><xsl:text>0</xsl:text></xsl:param>
	<xsl:param name="wpkgUser" ><xsl:text>0</xsl:text></xsl:param>
	<xsl:param name="login" ><xsl:text></xsl:text></xsl:param>
	<xsl:param name="MAJPackages" select="false()" />
	<xsl:param name="Debug" select="false()" />
	<!-- url d'upload des appli.xml : http://se3:909/wpkg/admin.php?upload=1 -->
	<xsl:param name="urlUpload" select="'index.php?upload=1'"/>

	<!-- url fournissant les packages officiels pour se3 
			pas besoin d'un serveur sécurisé car le md5sum des fichiers appli.xml 
			est ensuite controlé sur le serveur se3 avant l'installation -->
	<xsl:param name="urlWawadeb" select="'http://www.crdp.ac-caen.fr/forum/index.php'" />
	<!-- url fournissant le xml des packages du forum (nom de variable à changer!). -->
	<xsl:param name="urlWawadebMD5" select="'http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php'" />

	<xsl:param name="Local" select="false()" />
	<xsl:variable name="WPKGROOT" select="'/var/se3/unattended/install/wpkg'" />
	<xsl:variable name="INSTALLATIONS" select="document('/var/se3/unattended/install/wpkg/tmp/timeStamps.xml')/installations" />
	<xsl:variable name="PACKAGES" select="/wpkg/packages" />
	<!-- xsl:variable name="DocWPKGList">
		<xsl:choose>
			<xsl:when test="$urlWawadebMD5 = 'http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php?branch=testing'">
				<xsl:value-of select="'/var/www/se3/wpkg/se3_wpkglist.php?branch=testing'" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'/var/www/se3/wpkg/se3_wpkglist.php'" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable -->
	<xsl:variable name="DocWPKGList"><xsl:value-of select="'/var/www/se3/wpkg/forum.xml'" /></xsl:variable>
	<!-- xsl:variable name="WPKGLIST" select="document($DocWPKGList)/packages/package[concat(@id, '.xml') = @xml]" / -->
	<xsl:variable name="WPKGLIST" select="document('/var/www/se3/wpkg/forum.xml')/packages/package" />

	<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$MAJPackages = '1'" >
				<!-- xsl:choose>
					<xsl:when test="$urlWawadebMD5 = 'http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php?branch=testing'">
						<h2 style="color:#FF7F50;">Mise à jour des applications - Paquets WPKG a tester</h2>
					</xsl:when>
					<xsl:otherwise -->
						<h2>Mise à jour des applications</h2>
					<!-- /xsl:otherwise>
				</xsl:choose -->
				<xsl:choose>
					<xsl:when test="count($WPKGLIST) = 0" >
						Erreur : <xsl:value-of select="$urlWawadebMD5"/> n'est pas accessible !
					</xsl:when>
					<xsl:otherwise>
						<!-- xsl:choose>
							<xsl:when test="$urlWawadebMD5 = 'http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php?branch=testing'">
								Les mises à jour proposées ici sont celles des <a href="http://www.crdp.ac-caen.fr/forum/viewforum.php?f=9" target="_blank">Paquets WPKG a tester</a> du Forum du CRDP de Basse-Normandie.
							</xsl:when>
							<xsl:otherwise>
								Les mises à jour proposées ici sont celles des <a href="http://www.crdp.ac-caen.fr/forum/viewforum.php?f=10" target="_blank">Paquets WPKG Stables</a> du Forum du CRDP de Basse-Normandie.
							</xsl:otherwise>
						</xsl:choose -->
						Les mises à jour proposées ici sont celles des paquets WPKG du <a href="http://www.crdp.ac-caen.fr/forum/" target="_blank">Forum du CRDP de Basse-Normandie</a>.
						
						<form name="formUpdateXml" method="post" action="index.php?UpdateApplis=1" enctype="multipart/form-data">
							<table align="center">
								<tr>
									<td>
										Si vous avez déjà placé les fichiers nécessaires aux applications, sur le serveur: <br/>
										<input name="noDownload" value="1" type="checkbox"></input>Ne pas télécharger les fichiers d'installation des applications.<br></br><br></br>
										Pour ne pas contrôler les applications téléchargées : <br></br>
										<input name="ignoreWawadebMD5" onclick="if(this.checked) alert('Soyez sûr du contenu du fichier xml que vous allez installer sur le serveur!\nAucun contrôle ne sera effectué !\n\nLa sécurité de votre réseau est en jeu !!');" value="1" type="checkbox"></input>Ignorer le contrôle MD5.<br></br><br></br>
										<input size="80" name="urlWawadebMD5" id="urlWawadebMD5" value="{$urlWawadebMD5}" type="hidden"></input>
									</td>
								</tr>
							</table>
							<div id="divTableau">
								<table class="postes">
									<thead id="headTableau">
										<tr>
											<th style="cursor:ne-resize;" onclick="tri(1,event);"></th>
											<th style="cursor:ne-resize;" onclick="tri(2,event);">Fichier xml</th>
											<th style="cursor:ne-resize;" onclick="tri(3,event);">Info Forum</th>
											<th style="cursor:ne-resize;" onclick="tri(4,event);">Date du fichier officiel</th>
											<th style="cursor:ne-resize;" onclick="tri(5,event);">Etat</th>
											<!--
											<th>md5sum officiel</th>
											<th>md5sum local</th>
											-->
											<th style="cursor:ne-resize;" onclick="tri(6,event);">Installé le</th>
											<th style="cursor:ne-resize;" onclick="tri(7,event);">Par</th>
										</tr>
									</thead>
									<tbody id="bodyTableau">
									</tbody>
								</table>
							</div>
							<script id="ScriptTableau" type="text/javascript"><xsl:text>Tableau = new Array();&#xa;</xsl:text>
								<xsl:for-each select="$WPKGLIST" >
									<xsl:sort select="concat(translate(@id, $ucletters, $lcletters), @forum)" />
									<xsl:variable name="idEnCours" select="@id"/>
									<xsl:variable name="forumEnCours" select="@forum"/>
									<xsl:variable name="autreforumExiste" select="$WPKGLIST[(@id = $idEnCours) and not(@forum = $forumEnCours)]/@forum" />
									<xsl:variable name="xmlRef" select="@xml"/>
									<xsl:variable name="idsXml" select="$INSTALLATIONS/package[op/@xml = $xmlRef]"/>
									<xsl:variable name="opXml" select="$INSTALLATIONS/package[@id = $idsXml/@id]/op[last()]"/>
									<xsl:variable name="etat" >
										<xsl:choose>
											<xsl:when test="($opXml/@op = 'add') and (@md5sum = $opXml/@md5sum)">
												<xsl:text>A jour</xsl:text>
											</xsl:when>
											<xsl:when test="($opXml/@op = 'add')">
												<!-- appli installée et md5 différents -->
												<xsl:text>XML du forum </xsl:text><xsl:value-of select="$forumEnCours" /><xsl:text> différent</xsl:text>
											</xsl:when>
											<xsl:when test="$PACKAGES/package[@id = $idsXml/@id]">
												<!-- appli installée avant version se3-wpkg_0.2-0_i386.deb : xml inconnu -->
												<xsl:text>XML utilisé inconnu</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:text>Non installé</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:variable name="couleur" >
										<xsl:choose>
											<xsl:when test="($opXml/@op = 'add') and (@md5sum = $opXml/@md5sum)">
												<xsl:text>black</xsl:text>
											</xsl:when>
											<xsl:when test="($opXml/@op = 'add')">
												<!-- appli installée et md5 différents (Maj dispo) -->
												<xsl:text>#000099</xsl:text>
											</xsl:when>
											<xsl:when test="$PACKAGES/package[@id = $idsXml/@id]">
												<!-- appli installée avant version se3-wpkg_0.2-0_i386.deb : xml inconnu -->
												<xsl:text>#FF7F50</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:text>#696969</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:variable name="BGcouleur" >
										<xsl:choose>
											<xsl:when test="($opXml/@op = 'add') and (@md5sum = $opXml/@md5sum)">
												<!-- appli installée et à jour  bleu -->
												<xsl:text>#b3cce5</xsl:text>
											</xsl:when>
											<xsl:when test="($opXml/@op = 'add')">
												<!-- appli installée et md5 différents (Maj dispo) orange -->
												<xsl:text>#FFA500</xsl:text>
											</xsl:when>
											<xsl:when test="$PACKAGES/package[@id = $idsXml/@id]">
												<!-- appli installée avant version se3-wpkg_0.2-0_i386.deb : xml inconnu -->
												<xsl:text>#FF7F50</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<!-- appli non installée -->
												<xsl:text>ghostwhite</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:text>Tableau[</xsl:text><xsl:value-of select="position() - 1" /><xsl:text>] = new Array('</xsl:text>
<xsl:text>&lt;tr style="color:</xsl:text><xsl:value-of select="$couleur" /><xsl:text>;" title="</xsl:text><xsl:value-of select="$etat" /><xsl:text>"&gt;</xsl:text>
<xsl:text>&lt;td style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" </xsl:text>
<xsl:choose>
	<xsl:when test="($opXml/@op = 'add') and (@md5sum = $opXml/@md5sum)">
			<xsl:text>title="Le xml officiel est le même que le votre" &gt;&lt;input </xsl:text>
		</xsl:when>
		<xsl:when test="($opXml/@op = 'add')">
			<!-- appli installée et md5 différents -->
			<!-- xsl:text>title="Le xml officiel est différent du votre" &gt;&lt;input checked="true" </xsl:text -->
			<xsl:text>title="Le xml officiel est différent du votre" &gt;&lt;input </xsl:text>
		</xsl:when>
		<xsl:when test="$PACKAGES/package[@id = $idsXml/@id]">
			<!-- appli installée avant version se3-wpkg_0.2-0_i386.deb : xml inconnu -->
			<!-- xsl:text>title="Fichier xml utilisé pour l&amp;apos;installation inconnu" &gt;&lt;input checked="true" </xsl:text -->
			<xsl:text>title="Fichier xml utilisé pour l&amp;apos;installation inconnu" &gt;&lt;input </xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>&gt;&lt;input </xsl:text>
		</xsl:otherwise>
	</xsl:choose>
<xsl:text>onclick="onclickSelectMajAppli(this.checked, </xsl:text><xsl:value-of select="position() - 1" /><xsl:text>,' + "'</xsl:text><xsl:value-of select="$forumEnCours" /><xsl:text>', " + "'</xsl:text><xsl:value-of select="$autreforumExiste" /><xsl:text>');" + '" name="chk[]" value="</xsl:text><xsl:value-of select="concat(@forum, ':', $xmlRef, ':', @url)" /><xsl:text>" type="checkbox"&gt;&lt;/input&gt;&lt;/td&gt;</xsl:text>
<xsl:text>&lt;td align="center" style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;"&gt;&lt;a class="postes" style="background-color:transparent;font-weight:bolder;" title="Cliquer pour voir le contenu du xml" href="</xsl:text><xsl:value-of select="@url" /><xsl:text>" target="_blank"&gt;</xsl:text><xsl:value-of select="$xmlRef" /><xsl:text>&lt;/a&gt;&lt;/td&gt;</xsl:text>
<xsl:text>&lt;td align="center" style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" &gt;</xsl:text>
<xsl:choose>
	<xsl:when test="@topic_id > 0">
		<xsl:text>&lt;a style="background-color:transparent;" title="Cliquer pour accéder au message du forum" target="_blank" href="http://www.crdp.ac-caen.fr/forum/viewtopic.php?t=</xsl:text><xsl:value-of select="@topic_id" />
		<xsl:choose>
			<xsl:when test="(@forum = 'stable') or (@forum = 'test')">
				<xsl:text>"  &gt;&lt;img border="0" style="background-color:transparent;" src="img/forum_message.gif" width="12px" height="13px"&gt; </xsl:text><xsl:value-of select="@forum" /><xsl:text> &lt;/a&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>"  &gt;&lt;img border="0" style="background-color:transparent;" src="img/forum_message.gif" width="12px" height="13px"&gt;&lt;/a&gt;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:when>
	<xsl:otherwise>
		<xsl:text> </xsl:text>
	</xsl:otherwise>
</xsl:choose>
<xsl:text>&lt;/td&gt;</xsl:text>
<xsl:text>&lt;td style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" &gt;' + dateFromIso8601('</xsl:text><xsl:value-of select="@date" /><xsl:text>') + '&lt;/td&gt;</xsl:text>
<xsl:text>&lt;td style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" &gt;</xsl:text><xsl:value-of select="$etat" /><xsl:text>&lt;/td&gt;</xsl:text>
<xsl:text>&lt;td style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" &gt;</xsl:text>
<xsl:choose>
	<xsl:when test="$opXml/@op = 'del'">
		<xsl:text>&lt;div style="color:red;" title="Cette application a été désinstallée." &gt;' + dateFromIso8601('</xsl:text><xsl:value-of select="$opXml/@date" /><xsl:text>') + '&lt;/div&gt;</xsl:text>
	</xsl:when>
	<xsl:otherwise>
		<xsl:text>' + dateFromIso8601('</xsl:text><xsl:value-of select="$opXml/@date" /><xsl:text>') + '</xsl:text>
	</xsl:otherwise>
</xsl:choose>
<xsl:text>&lt;/td&gt;&lt;td style="background-color:</xsl:text><xsl:value-of select="$BGcouleur" /><xsl:text>;" &gt;</xsl:text><xsl:value-of select="$opXml/@user" /><xsl:text>&lt;/td&gt;</xsl:text>
<xsl:text>&lt;/tr&gt; &lt;!--',</xsl:text>
<!-- Clé de tri1 checked-->
<!-- xsl:value-of select="($opXml/@op = 'add') and not(@md5sum = $opXml/@md5sum)" /><xsl:text>','</xsl:text -->
<xsl:text>false,'</xsl:text>
<!-- Clé de tri2 FichierXml -->
<xsl:value-of select="translate($xmlRef, $ucletters, $lcletters)" /><xsl:text>','</xsl:text>
<!-- Clé de tri3 EX topic_id   forum : stable ou test-->
<xsl:value-of select="@forum" /><xsl:text>','</xsl:text>
<!-- xsl:choose>
	<xsl:when test="@topic_id > 0">
		<xsl:choose>
			<xsl:when test="@forum = 'stable'">
				<xsl:value-of select="10000 + @topic_id" /><xsl:text>,'</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@topic_id" /><xsl:text>,'</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:when>
	<xsl:otherwise>
		<xsl:choose>
			<xsl:when test="@forum = 'stable'">
				<xsl:text>10000,'</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>0,'</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:otherwise>
</xsl:choose -->
<!-- Clé de tri4 DateFichierOfficiel -->
<xsl:value-of select="@date" /><xsl:text>','</xsl:text>
<!-- Clé de tri5 Etat -->
<xsl:value-of select="$etat" /><xsl:text>','</xsl:text>
<!-- Clé de tri6 InstalléLe -->
<xsl:value-of select="$opXml/@date" /><xsl:text>','</xsl:text>
<!-- Clé de tri7 Par -->
<xsl:value-of select="$opXml/@user" /><xsl:text>',</xsl:text>
<!-- Numéro de la ligne -->
<xsl:value-of select="position() - 1" /><xsl:text>,'--&gt;');&#xa;</xsl:text>

								</xsl:for-each>
							</script>
							<br/>
							<xsl:choose>
								<xsl:when test="not($wpkgAdmin = '1')" >
									
									<div class="error_msg"><input name="Installer" disabled="true" value=" Installer les applications sélectionnées " type="submit" ></input> Vous n'êtes pas autorisé à ajouter de nouvelles applications sur ce serveur.</div>
									<p>Demandez à l'administrateur de le faire pour vous !</p>
								</xsl:when>
								<xsl:otherwise >
									<input name="Installer" value=" Installer les applications sélectionnées " type="submit" ></input>
								</xsl:otherwise>
							</xsl:choose>
						</form>
						<br/>
						<!-- xsl:choose>
							<xsl:when test="$urlWawadebMD5 = 'http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php?branch=testing'">
								<a href="javascript:void(0);" onclick="urlWawadebMD5='http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php';testUpdatedXml();" >Afficher les applications stables</a> disponibles dans le Forum du CRDP de Basse-Normandie : <a href="http://www.crdp.ac-caen.fr/forum/viewforum.php?f=10" target="_blank">Paquets WPKG Stables</a>.
							</xsl:when>
							<xsl:otherwise>
								<a href="javascript:void(0);" onclick="urlWawadebMD5='http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php?branch=testing';testUpdatedXml();" >Afficher les applications à tester</a> disponibles dans le Forum du CRDP de Basse-Normandie : <a href="http://www.crdp.ac-caen.fr/forum/viewforum.php?f=9" target="_blank">Paquets WPKG a tester</a>.
							</xsl:otherwise>
						</xsl:choose -->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$Debug">
					<pre>Debug=<xsl:value-of select="$Debug" /></pre>
				</xsl:if>
				<div style="position:relative; 
						left:0px; 
						top:0px; 
						z-index:0;">
					<!-- Pour le fun, appel de templates -->
					<!--	 Titre du document -->
					<xsl:call-template name="MisesAjour" />
					<xsl:call-template name="titre" />
					<xsl:call-template name="explication" />
					<xsl:call-template name="uploadSe3" />
					
				</div>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="MisesAjour">
		<h2>Mises à jour</h2>
		<div id="updatedXml">
			<table>
				<tr>
					<td><p>Pour mettre à jour ou installer des paquets WPKG à partir du <a href="http://www.crdp.ac-caen.fr/forum/" target="_blank">forum du CRDP de Caen</a> : </p></td>
					<td>
						<input value="Afficher les applications disponibles" type="button" onclick="MAJPackages=1;urlWawadebMD5='http://www.crdp.ac-caen.fr/forum/se3_wpkglist.php';testUpdatedXml();"></input><br/><br/>
						<input name="forceRefresh" id="forceRefresh" value="0" type="checkbox" title="Récupérer les données du forum même si elle ne semble pas avoir été modifiées"></input>forçer le rafraîchissement.<br/>
						
					</td>
				</tr>
			</table>
N'oubliez pas, après avoir installé une application de vous rendre sur le forum, pour indiquer si l'application s'installe correctement ou non sur les postes de votre réseau. Vous contribuerez ainsi à améliorer la qualité des applications proposées.
		</div>
	</xsl:template>

	<xsl:template name="titre">
			<h2>Ajout d'une application à déployer par le réseau.</h2>
	</xsl:template>

	<xsl:template name="explication">
		<div>
			<h3>Information</h3>
			En dehors du <a href="{$urlWawadeb}" target="_blank">forum</a>,
			vous pouvez ajouter une application de votre cru ou inspirée d'applications téléchargées sur internet (voir 'Compléments' plus bas).<br></br>
			<dir>
				<li >Télécharger ou créer un fichier (*.xml) de définition d'application.</li>
				<dir>
					<li >Indiquer, dans le formulaire ci-dessous, l'emplacement de ce fichier xml.</li>
					<li >Cliquer sur 'ajouter cette application'.</li>
					<li >Votre serveur effectuera les téléchargements nécessaires à l'installation.</li>
				</dir>
				<li >Cocher les profils (parcs de machines) sur lesquels vous souhaitez installer ces applications (onglet <a href="javascript:ChangePageEnCoursFromMenu('PackagesProfiles');">Associations Appli.&lt;-&gt;Parcs</a>).</li>
				<li >Au prochain démarrage des postes appartenant à ces profils, les applications seront installées.</li>
			</dir>
		</div>
	</xsl:template>

	<xsl:template name="uploadSe3">
		<form name="formulaire" method="post" action="{$urlUpload}" enctype="multipart/form-data">
			<h3>Fichier d'application à ajouter</h3>
			<table align="center">
				<tr>
					<td>
						Si vous avez déjà placé les fichiers nécessaires à l'application, sur le serveur: <br></br>
						<input name="noDownload" value="1" type="checkbox"></input>Ne pas télécharger les fichiers d'installation de cette application.<br></br><br></br>
						Pour ajouter une application qui n'est pas répertoriée sur le serveur de référence, cocher cette case : <br></br>
						<input name="ignoreWawadebMD5" value="1" onclick="if(this.checked) alert('Soyez sûr du contenu du fichier xml que vous allez installer sur le serveur!\nAucun contrôle ne sera effectué !\n\nLa sécurité de votre réseau est en jeu !!');" type="checkbox"></input>Ignorer le contrôle MD5.<br></br><br></br>
					</td>
				</tr>
				<tr>
					<td>
						Fichier xml de définition de l'application :<br></br>
						<xsl:choose>
							<xsl:when test="not($wpkgAdmin = '1')" >
								<input title="chemin du fichier xml" disabled="true" size="70" name="appliXml" type="file"></input><input value="Ajouter cette application !" disabled="true" type="submit"></input>
								<div class="error_msg">Vous n'êtes pas autorisé à ajouter de nouvelles applications sur ce serveur.</div>
								<p>Demandez à l'administrateur de le faire pour vous !</p>
							</xsl:when>
							<xsl:otherwise >
								<input title="chemin du fichier xml" size="70" name="appliXml" type="file"></input><input value="Ajouter cette application !" type="submit"></input>
							</xsl:otherwise>
						</xsl:choose>
						
					</td>
				</tr>
			</table>
			<br></br>
			<!--
			Vous pouvez définir ici l'url du fichier de contrôle des applications téléchargées.<br/>
			L'URL saisie doit être sur un site de confiance. La sécurité de votre réseau en dépend !<br/>
			Par défaut, seules les applications de la branche stable sont prises en compte !<br/>

			-->
			<input size="80" name="urlWawadebMD5" id="urlWawadebMD5" value="{$urlWawadebMD5}" type="hidden"></input><br></br><br></br>

		</form>

		<h3>Compléments</h3>
		D'autres fichiers xml de définition d'applications sont disponibles sur internet.<br></br>
		Le plus souvent, ces fichiers devront d'être adaptés pour fonctionner sur votre réseau.<br></br>
		Voici quelques liens :<br></br>
		<a href="http://wpkg.linuxkidd.com/live/packages_list.php">http://wpkg.linuxkidd.com/live/packages_list.php</a><br></br>
		<a href="http://wpkg.org/index.php/Category:Silent_Installers">http://wpkg.org/index.php/Category:Silent_Installers</a><br></br>
		<a href="http://www.sp.phy.cam.ac.uk/%7Erl201/wpkg/licences.php?action=listsoftware">http://www.sp.phy.cam.ac.uk/~rl201/wpkg/licences.php?action=listsoftware</a>
		
		 <br></br><br></br>
	</xsl:template>
	
</xsl:stylesheet>
