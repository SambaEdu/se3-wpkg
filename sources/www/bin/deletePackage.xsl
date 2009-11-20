<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
	<!-- Génère les commandes bash de désinstallation de l'appli sur le serveur!.
			S'applique à profiles.xml  
			Est appelé par deletePackage.sh
	-->
	<xsl:output method="text" encoding="iso-8859-1"/>
	<xsl:param name="debug">0</xsl:param>
	<xsl:param name="Appli"></xsl:param>
	<!-- deleteFiles de la forme ' 1 3 4 ' -->
	<xsl:param name="deleteFiles"></xsl:param>
	<xsl:variable name="PROFILES" select="/profiles"/>
	<xsl:variable name="PACKAGES" select="document('/var/se3/unattended/install/wpkg/packages.xml')/packages"/>

	<xsl:template match="/">
		<xsl:text># Vérification des dépendances d'applications&#x00a;</xsl:text>
		<xsl:choose>
			<xsl:when test="$PACKAGES/package/depends[@package-id = $Appli]" >
				<xsl:text>echo "Erreur : L'appli '</xsl:text><xsl:value-of select="$Appli"/><xsl:text>' est requise pour les applications : </xsl:text>
				<xsl:for-each select="$PACKAGES/package[ depends/@package-id = $Appli]">
					<xsl:value-of select="@id"/><xsl:text> </xsl:text>
				</xsl:for-each>
				<xsl:text>."&#x00a;</xsl:text>
				<xsl:text>Erreur=1&#x00a;</xsl:text>
			</xsl:when>
			<xsl:otherwise >
				<xsl:text>echo "Aucune application installée n'a besoin de </xsl:text><xsl:value-of select="$Appli"/><xsl:text>"&#x00a;</xsl:text>
				<xsl:choose>
					<xsl:when test="$PACKAGES/package[@id = $Appli]" >
						<xsl:text>echo "Suppression des fichiers demandés"&#x00a;</xsl:text>
						<xsl:for-each select="$PACKAGES/package[@id = $Appli]/download/@saveto" >
							<xsl:choose>
								<xsl:when test="contains($deleteFiles, concat(' ', position(), ' '))" >
									<xsl:text>  if ( /bin/rm "</xsl:text><xsl:value-of select="."/><xsl:text>" ) ; then&#x00a;</xsl:text>
									<xsl:text>    echo "  Le fichier </xsl:text><xsl:value-of select="."/><xsl:text> a été effacé."&#x00a;</xsl:text>
									<xsl:text>  else&#x00a;</xsl:text>
									<xsl:text>    echo "  Erreur lors de l'effacement du fichier '</xsl:text><xsl:value-of select="."/><xsl:text>'."&#x00a;</xsl:text>
									<xsl:text>    Erreur=3&#x00a;</xsl:text>
									<xsl:text>  fi&#x00a;</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>  echo "  Le fichier </xsl:text><xsl:value-of select="."/><xsl:text> est conservé."&#x00a;</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					
						<xsl:text>if ( xsltproc --output /var/se3/unattended/install/wpkg/packages.xml --stringparam Appli "</xsl:text><xsl:value-of select="$Appli"/><xsl:text>" /var/www/se3/wpkg/bin/supprPackage.xsl /var/se3/unattended/install/wpkg/packages.xml ) ; then&#x00a;</xsl:text>
						<xsl:text>  echo "L'application </xsl:text><xsl:value-of select="$Appli"/><xsl:text> a été supprimée."&#x00a;</xsl:text>
						<xsl:text>else&#x00a;</xsl:text>
						<xsl:text>  echo "Erreur $? : xsltproc --output /var/se3/unattended/install/wpkg/packages.xml --stringparam Appli '</xsl:text><xsl:value-of select="$Appli"/><xsl:text>' /var/www/se3/wpkg/bin/supprPackage.xsl /var/se3/unattended/install/wpkg/packages.xml"&#x00a;</xsl:text>
						<xsl:text>  Erreur=4&#x00a;</xsl:text>
						<xsl:text>fi&#x00a;</xsl:text>
					</xsl:when>
					<xsl:otherwise >
						<xsl:text>echo "Erreur : L'appli &apos;</xsl:text><xsl:value-of select="$Appli"/><xsl:text>&apos; est introuvable dans packages.xml"&#x00a;</xsl:text>
						<xsl:text>Erreur=2&#x00a;</xsl:text>
					</xsl:otherwise >
				</xsl:choose>
			</xsl:otherwise >
		</xsl:choose>
		<xsl:text>&#x00a;</xsl:text>
	</xsl:template>
</xsl:stylesheet>