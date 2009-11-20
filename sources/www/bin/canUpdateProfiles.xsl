<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
	<!-- Teste si l'utilisateur $login a le droit de faire de faire les modifs demandées sur profiles.xml.
			S'applique à profiles.xml  
			Est appelé par deletePackage.sh
			
			## $Id$ ##
	-->
	<xsl:output method="text" encoding="iso-8859-1"/>
	<xsl:param name="debug">0</xsl:param>
	<xsl:param name="login"></xsl:param>
	<xsl:variable name="PROFILES" select="document('/var/se3/unattended/install/wpkg/profiles.xml')/profiles"/>
	<xsl:variable name="DROITS" select="document('/var/se3/unattended/install/wpkg/droits.xml')/droits"/>

	<xsl:template match="/">
		<xsl:text># login=</xsl:text><xsl:value-of select="$login"/><xsl:text>&#x00a;</xsl:text>
		<xsl:choose>
			<xsl:when test="$DROITS/droit[(@parc = '_TousLesPostes') and (@user = $login) and (@droit = 'admin')]" >
				<xsl:text>Droit admin _TousLespostes </xsl:text><xsl:value-of select="$login"/><xsl:text>&#x00a;</xsl:text>
				<xsl:text>OK&#x00a;</xsl:text>
			</xsl:when>
			<xsl:when test="$login = ''" >
				<xsl:text>NOK&#x00a;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$DROITS/droit[(@parc = '_TousLesPostes') and (@user = $login) and (@droit = 'manage')]" >
						<xsl:text>Droit manage _TousLesPostes pour </xsl:text><xsl:value-of select="$login"/><xsl:text>&#x00a;</xsl:text>
						<xsl:text>OK&#x00a;</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>OK&#x00a;</xsl:text>
						<xsl:for-each select="/profiles/profile" >
							<xsl:variable name="idProfile" select="@id"/>
							<xsl:variable name="ListPackage">
								<xsl:for-each select="*" >
									<xsl:value-of select="@package-id"/>
									<xsl:value-of select="@profile-id"/>
								</xsl:for-each>
							</xsl:variable>
							<xsl:variable name="ListPackageActuel">
								<xsl:for-each select="$PROFILES/profile[@id = $idProfile]/*" >
									<xsl:value-of select="@package-id"/>
									<xsl:value-of select="@profile-id"/>
								</xsl:for-each>
							</xsl:variable>
							<!-- <xsl:text>profile en cours = </xsl:text><xsl:value-of select="$idProfile"/><xsl:text>&#x00a;</xsl:text> -->
							<xsl:if test="not($ListPackage = $ListPackageActuel)" >
								<xsl:if test="not($DROITS/droit[(@parc = $idProfile) and (@user = $login) and (@droit = 'manage')])" >
									<xsl:value-of select="concat($idProfile,' : ListPackage=', $ListPackage, '!=', $ListPackageActuel)"/><xsl:text> NOK&#x00a;</xsl:text>
								</xsl:if>
							</xsl:if>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>