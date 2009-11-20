<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet xmlns:xsl = "http://www.w3.org/1999/XSL/Transform" version = "1.0" >
   <xsl:output method="xml" version="1.0" encoding="iso-8859-1" indent="yes" />
   <xsl:variable name="forumStable" select="/packages"/>
   <xsl:variable name="forumTest" select="document('/var/www/se3/wpkg/se3_wpkglist.php?branch=testing')/packages"/>
   <!-- 
	Concatène les fichiers xml se3_wpkglist.php et se3_wpkglist.php?branch=testing
	## $Id$ ##

	xsltproc -o /var/www/se3/wpkg/forum.xml /var/www/se3/wpkg/bin/mergeForum.xsl 'se3_wpkglist.php'
	
   -->

	<xsl:template match="/">
		<!-- insère le noeud racine ( /packages )-->
		<xsl:element name = "packages" >
			<xsl:for-each select="$forumStable/package" >
				<xsl:element name = "package" >
					<xsl:attribute name="forum" >stable</xsl:attribute>
					<xsl:apply-templates select = "@*"/>
				</xsl:element>
			</xsl:for-each>

			<xsl:for-each select="$forumTest/package" >
				<xsl:element name = "package" >
					<xsl:attribute name="forum" >test</xsl:attribute>
					<xsl:apply-templates select = "@*"/>
				</xsl:element>
			</xsl:for-each>

		</xsl:element>
	</xsl:template>
	
	<xsl:template match="@*">
		<!-- recopie les attributs -->
		<xsl:copy />
	</xsl:template>

</xsl:stylesheet>
