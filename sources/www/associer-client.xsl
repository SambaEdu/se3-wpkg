<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="utf-8" indent="yes" />
	<!-- Ajoute ou retire une application d'un profile
			S'applique à wpkg.xml 
			Est utilisé par le client pour mettre à jour wpkg.xml
			
		## $Id$ ##
	-->
	<xsl:param name="debug">0</xsl:param>
	<xsl:param name="operation"></xsl:param>
	<xsl:param name="idPackage"></xsl:param>
	<xsl:param name="idProfile"></xsl:param>
	
	<xsl:key name="ProfileFromId" match="/wpkg/profiles/profile" use="@id" />
	
	<xsl:variable name="PROFILES" select="/wpkg/profiles"/>
	<xsl:variable name="dependParcs" select="key('ProfileFromId', $idProfile)/depends/@profile-id"/>
	
	<xsl:template match="*">
		<!-- recopie le noeud -->
		<xsl:copy>
			<xsl:apply-templates select="@*" />
			<xsl:apply-templates select="comment()|processing-instruction()" />
			<xsl:apply-templates select="*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="@*">
		<!-- recopie les attributs -->
		<xsl:copy />
	</xsl:template>

	<xsl:template match="comment()|processing-instruction()">
		<xsl:copy />
	</xsl:template>

	<xsl:template match="/wpkg/profiles/profile">
		<xsl:choose>
			<xsl:when test="@id = $idProfile">
				<!-- recupère les packages associés depuis profiles.xml -->
				<xsl:element name="profile">
					<xsl:apply-templates select="@*" />
					<xsl:apply-templates select="comment()|processing-instruction()" />
					<xsl:for-each select="*">
						<xsl:if test="not(@package-id = $idPackage)">
							<xsl:copy-of select="." />
						</xsl:if>
					</xsl:for-each>
					<xsl:if test="$operation = 'Associer'" >
						<package package-id="{$idPackage}" />
					</xsl:if>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="." />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>