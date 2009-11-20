<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
	<xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes"/>
	<!--	 Met à jour tmp/timeStamps.xml 
			S'applique à /var/se3/unattended/install/wpkg/tmp/timeStamps.xml
	
			## $Id$ ##
	-->
	<xsl:param name="op" select="'add'" />  <!-- operation : add|del -->
	<xsl:param name="Appli" select="''" />  <!-- package id -->
	<xsl:param name="AppliXml" select="''" />  <!-- Nom du fichier xml contenant la definition de l'appli -->
	<xsl:param name="TimeStamp" select="''" />  <!-- date actuelle au format 2007-06-05T10:20:25+0200 -->
	<xsl:param name="md5sum" select="''" />  <!-- md5sum du fichier utilisé pour ajouter l'appli -->
	<xsl:param name="user" select="''" />  <!-- utilisateur qui effectue l'operation -->

	<xsl:template match="/">
		<xsl:comment><xsl:text> Généré par SambaEdu. Ne pas modifier </xsl:text></xsl:comment>
		<xsl:element name="installations">
			<xsl:for-each select="/installations/package">
				<xsl:copy >
					<xsl:apply-templates select="@*" />
					<xsl:apply-templates select="comment()|processing-instruction()" />
					<xsl:copy-of select="*" />
					<xsl:if test="@id = $Appli">
						<xsl:call-template name = "AddInstallationPackage" />
					</xsl:if>
				</xsl:copy>
			</xsl:for-each>
			<xsl:if test="not(/installations/package[@id = $Appli])">
				<xsl:element name="package">
					<xsl:attribute name = "id" ><xsl:value-of select="$Appli" /></xsl:attribute>
					<xsl:call-template name = "AddInstallationPackage" />
				</xsl:element>
			</xsl:if>
		</xsl:element>
	</xsl:template>
	
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

	<xsl:template name="AddInstallationPackage" >
		<xsl:element name="op">
			<xsl:attribute name = "op" ><xsl:value-of select="$op" /></xsl:attribute>
			<xsl:attribute name = "date" ><xsl:value-of select="$TimeStamp" /></xsl:attribute>
			<xsl:if test="not($AppliXml = '')" >
				<xsl:attribute name = "xml" ><xsl:value-of select="$AppliXml" /></xsl:attribute>
			</xsl:if>
			<xsl:if test="not($md5sum = '')" >
				<xsl:attribute name = "md5sum" ><xsl:value-of select="$md5sum" /></xsl:attribute>
			</xsl:if>
			<xsl:if test="not($user = '')" >
				<xsl:attribute name = "user" ><xsl:value-of select="$user" /></xsl:attribute>
			</xsl:if>
		</xsl:element>
	</xsl:template>
	
</xsl:stylesheet>
